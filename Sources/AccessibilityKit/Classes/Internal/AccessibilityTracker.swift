//
//  AccessibilityTracker.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

///
/// Holds the tracking configuration, owns a subject per tracked feature,
/// records each feature's history for the session, and delivers snapshots to
/// the app's observations and updates to any listeners — the kit — which are
/// held weakly and never disturb the observations. An update carries what
/// the kit shows: the snapshot, each feature's displayed history and the
/// tracking status, worked out together so they agree.
///
/// Everything it does is main-actor work — reading accessibility state means
/// touching `@MainActor` UIKit statics — so the main actor serialises subject
/// configuration against snapshot creation, and no queue of its own is needed.
/// Completions are delivered asynchronously, on its delivery queue: the main
/// queue outside tests.
///
@MainActor
final class AccessibilityTracker {

    // MARK: - Internal properties

    static let shared = AccessibilityTracker()

    ///
    /// What the kit says about tracking now, so a screen shows the right
    /// status from its first frame, before its first update lands.
    ///
    var trackingStatus: TrackingStatus {
        return status(at: Date())
    }

    // MARK: - Private properties

    private var configuration: AccessibilityTrackingConfiguration? {
        didSet { configurationDidChange() }
    }
    ///
    /// Bumped on every reconfiguration, so a snapshot in flight can tell
    /// whether the configuration it was taken under is still the current
    /// one.
    ///
    private var configurationGeneration = 0
    /// The app's observations, in the order they were registered.
    private var completions = [(id: Int, state: ObservationState, completion: (AccessibilitySnapshot) -> Void)]()
    private var nextObservationID = 0
    private var listeners = [WeakListener]()
    private var subjects = [Subject]()
    private var history = AccessibilitySessionHistory()
    ///
    /// Recorded values through their transform, by identifier and entry
    /// sequence, valid for the configuration generation they were worked out
    /// under, so each recorded value is transformed only once.
    ///
    private var displayedValues = [String: [Int: AccessibilityValue]]()
    private var displayedValuesGeneration: Int?
    private let notificationCenter: NotificationCenter
    private let readState: AccessibilityStateReader
    private let launchDate: Date?
    private let isPrewarmed: Bool
    private let deliveryQueue: any DeliveryQueue

    // MARK: - Lifecycle

    ///
    /// - Parameters:
    ///   - notificationCenter: Where the features' change notifications are posted.
    ///   - readState: How a feature's current state is read. Tests supply
    ///     their own, so values can change on cue.
    ///   - launchDate: When the app launched, so history started soon after
    ///     reads as "at launch".
    ///   - isPrewarmed: Whether the system started the process ahead of the
    ///     launch, in which case the first configuration counts as the launch.
    ///   - deliveryQueue: Where deliveries run, on a later main-queue turn.
    ///     Tests supply one they run step by step.
    ///
    init(
        notificationCenter: NotificationCenter = .default,
        readState: @escaping AccessibilityStateReader = AccessibilityType.readSystemState,
        launchDate: Date? = ProcessLaunch.date,
        isPrewarmed: Bool = ProcessLaunch.isPrewarmed,
        deliveryQueue: any DeliveryQueue = MainDeliveryQueue()
    ) {
        self.notificationCenter = notificationCenter
        self.readState = readState
        self.launchDate = launchDate
        self.isPrewarmed = isPrewarmed
        self.deliveryQueue = deliveryQueue
    }

    // MARK: - Internal methods

    func currentAccessibilitySnapshot(for objects: [AccessibilityTrackingObject]) -> AccessibilitySnapshot {
        return AccessibilitySnapshot(trackingObjects: objects, readState: readState)
    }

    func configureAccessibilityTracking(with configuration: AccessibilityTrackingConfiguration) {
        self.configuration = configuration
    }

    ///
    /// Registers an observation alongside any others. It receives its own
    /// first snapshot if tracking is configured, and every change under a
    /// continuous configuration, until the returned observation ends.
    ///
    func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) -> AccessibilityObservation {
        let id = nextObservationID
        nextObservationID += 1
        let observation = AccessibilityObservation { [weak self] in
            guard let self, let index = self.completions.firstIndex(where: { $0.id == id }) else { return }
            // Taken out first and released after the array access ends: the
            // completion may hold the last reference to another observation,
            // whose cancellation would otherwise modify the array mid-removal.
            let removed = self.completions.remove(at: index)
            withExtendedLifetime(removed) { }
        }
        completions.append((id: id, state: observation.state, completion: completion))
        // Still alive a turn later means the caller kept it.
        let state = observation.state
        deliveryQueue.schedule { state.markKept() }

        takeAndDeliverSnapshot(toObservations: [id], listeners: [], reason: .registration)

        return observation
    }

    ///
    /// Registers an additional, weakly held listener — the kit — without
    /// touching the app's observations. It receives an update on
    /// registration if tracking is configured, every change under a
    /// continuous configuration, and a refresh each time tracking is
    /// configured, which is how a listener registered first is filled in.
    /// Registering a listener that is already registered does nothing, and
    /// hands it nothing.
    ///
    func addListener(_ listener: TrackerListener) {
        pruneListeners()
        guard !listeners.contains(where: { $0.listener === listener }) else { return }

        let entry = WeakListener(listener: listener)
        listeners.append(entry)
        takeAndDeliverSnapshot(toObservations: [], listeners: [entry], reason: .registration)
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityTracker: AccessibilityObserver {

    ///
    /// The system's value is recorded on every change, whoever is listening,
    /// so the session history is complete whenever the kit is opened later.
    /// It is the state the subject already read, so no app code runs for it.
    ///
    func accessibilityStateDidChange(_ state: AccessibilityState) {
        history.record(state, at: Date())

        guard configuration?.fetchType == .continuous else { return }
        pruneListeners()
        takeAndDeliverSnapshot(toObservations: completions.map(\.id), listeners: listeners, reason: .change)
    }
}

// MARK: - Private methods

private extension AccessibilityTracker {

    ///
    /// Subscribes to the new features, carries their history over, and hands
    /// listeners — the kit — the newly configured features without waiting
    /// for a change, so a screen never keeps showing rows for features that
    /// are no longer tracked, nor stays empty because its first update was
    /// dropped. The app's own observations are left alone: reconfiguring
    /// emits no snapshot to them.
    ///
    func configurationDidChange() {
        configurationGeneration += 1
        guard let configuration else { return }

        configureSubjects(for: configuration)

        // Read once, for the history and for the refresh below alike.
        let now = Date()
        let states = Dictionary(
            Set(configuration.objects.map(\.type)).map { ($0, readState($0)) },
            uniquingKeysWith: { first, _ in first }
        )
        // A prewarmed process started long before the launch, so its first
        // configuration is taken to be the launch.
        let atLaunch = isPrewarmed
            || launchDate.map { now.timeIntervalSince($0) < ProcessLaunch.window } ?? true
        history.track(Array(states.values), at: now, atLaunch: atLaunch)

        pruneListeners()
        takeAndDeliverSnapshot(
            toObservations: [],
            listeners: listeners,
            reason: .reconfiguration,
            readState: { [readState] type in states[type] ?? readState(type) }
        )
    }

    func configureSubjects(for configuration: AccessibilityTrackingConfiguration) {
        // The old subjects are released by the assignment below, and a
        // released subject takes its observer list and its notification
        // registration with it.
        subjects = Set(configuration.objects.map(\.type))
            .map { AccessibilitySubject(type: $0, notificationCenter: notificationCenter, readState: readState) }
        subjects.forEach { $0.addObserver(self) }
    }

    ///
    /// Takes a snapshot of the configured features, if tracking is
    /// configured, and their displayed histories when the kit is to be told.
    /// Transforms run for both, and one that reconfigures tracking leaves
    /// what was taken stale, so it is then discarded rather than returned.
    /// The histories hold exactly what was recorded by the time the snapshot
    /// was taken, since both are worked out in the same call.
    ///
    func takeConfiguredSnapshot(
        readState: AccessibilityStateReader? = nil,
        withHistories: Bool
    ) -> (snapshot: AccessibilitySnapshot, histories: [String: [AccessibilityHistoryEntry]], generation: Int)? {
        guard let configuration else { return nil }

        let generation = configurationGeneration
        let snapshot = AccessibilitySnapshot(trackingObjects: configuration.objects, readState: readState ?? self.readState)
        // Checked before the histories too, so their transforms never run
        // for a configuration that has already been replaced.
        guard generation == configurationGeneration else { return nil }
        let histories = withHistories ? displayedHistories(for: configuration.objects, generation: generation) : [:]
        guard generation == configurationGeneration else { return nil }
        return (snapshot, histories, generation)
    }

    ///
    /// Takes a snapshot for these recipients and delivers it. A snapshot
    /// nobody is registered to receive is not taken: whoever registers later
    /// is handed one of their own. The histories, which run the transforms
    /// over everything recorded, are worked out only when a listener is
    /// among the recipients.
    ///
    func takeAndDeliverSnapshot(
        toObservations ids: [Int],
        listeners: [WeakListener],
        reason: TrackerUpdate.Reason,
        readState: AccessibilityStateReader? = nil
    ) {
        let isListened = listeners.contains(where: { $0.listener != nil })
        guard !ids.isEmpty || isListened else { return }
        guard let taken = takeConfiguredSnapshot(readState: readState, withHistories: isListened) else { return }

        let update = TrackerUpdate(
            snapshot: taken.snapshot,
            histories: taken.histories,
            status: status(at: taken.snapshot.date),
            reason: reason
        )
        deliver(update, takenUnder: taken.generation, toObservations: ids, listeners: listeners)
    }

    ///
    /// Delivers on the delivery queue, never inside the call that scheduled
    /// it: the snapshot to the observations, then the update to the
    /// listeners. Both are captured now, so a delivery goes only to whoever
    /// was registered when it was taken.
    ///
    /// Each recipient is checked as it is reached. Once tracking has been
    /// reconfigured since the snapshot was taken — even by an earlier
    /// recipient of this same delivery — nobody further receives it, and an
    /// observation that has ended since is skipped: it is never called again.
    ///
    func deliver(
        _ update: TrackerUpdate,
        takenUnder generation: Int,
        toObservations ids: [Int],
        listeners: [WeakListener]
    ) {
        deliveryQueue.schedule { [weak self] in
            guard let self else { return }

            for id in ids {
                guard self.configurationGeneration == generation else { return }
                guard let entry = self.completions.first(where: { $0.id == id }), !entry.state.isCancelled else { continue }
                entry.completion(update.snapshot)
            }

            for entry in listeners {
                guard self.configurationGeneration == generation else { return }
                entry.listener?.trackerDidUpdate(update)
            }
        }
    }

    ///
    /// Each tracked feature's displayed history, keyed by identifier: its
    /// recorded values through its transform, and a change kept only when
    /// what the app reports changes, since a transform can fold several
    /// system values into one. Stops early, with nothing, once a transform
    /// has reconfigured tracking.
    ///
    func displayedHistories(
        for objects: [AccessibilityTrackingObject],
        generation: Int
    ) -> [String: [AccessibilityHistoryEntry]] {
        if displayedValuesGeneration != generation {
            displayedValues = [:]
            displayedValuesGeneration = generation
        }

        var histories = [String: [AccessibilityHistoryEntry]]()
        for object in objects {
            histories[object.identifier] = displayedHistory(for: object, generation: generation)
            guard generation == configurationGeneration else { return [:] }
        }
        return histories
    }

    func displayedHistory(for object: AccessibilityTrackingObject, generation: Int) -> [AccessibilityHistoryEntry] {
        var known = displayedValues[object.identifier] ?? [:]
        let entries = history.entries(for: object.type)

        var displayed = [AccessibilityHistoryEntry]()
        for entry in entries {
            let value: AccessibilityValue
            if let cached = known[entry.sequence] {
                value = cached
            } else {
                value = object.transform?(entry.value) ?? entry.value
                known[entry.sequence] = value
            }
            guard entry.kind != .change || value != displayed.last?.value else { continue }
            displayed.append(AccessibilityHistoryEntry(sequence: entry.sequence, date: entry.date, value: value, kind: entry.kind))
        }

        // A transform that reconfigured tracking has already started the
        // cache over for the new configuration: values from this one must
        // not land in it.
        guard generation == configurationGeneration else { return displayed }
        // Only what is still recorded is kept, so the cache stays as small as the history.
        let recorded = Set(entries.map(\.sequence))
        displayedValues[object.identifier] = known.filter { recorded.contains($0.key) }
        return displayed
    }

    func status(at date: Date) -> TrackingStatus {
        guard let configuration, !configuration.objects.isEmpty else { return .notTracked }
        return configuration.fetchType == .continuous ? .live : .snapshot(date)
    }

    func pruneListeners() {
        listeners.removeAll(where: { $0.listener == nil })
    }
}

// MARK: - Weak listener

///
/// Listeners are held weakly: the view model holds its tracker, so holding
/// it back would be a cycle, and a dismissed screen must stop being told
/// anything.
///
private struct WeakListener {

    weak var listener: TrackerListener?
}
