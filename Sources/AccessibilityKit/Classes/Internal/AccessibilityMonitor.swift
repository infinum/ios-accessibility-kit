//
//  AccessibilityMonitor.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

///
/// Holds the tracking configuration, owns a subject per tracked feature,
/// records each feature's history for the session, and delivers snapshots to
/// the app's observations and to any snapshot observers — the kit's UI —
/// which are held weakly and never disturb the observations.
///
/// Everything it does is main-actor work — reading accessibility state means
/// touching `@MainActor` UIKit statics — so the main actor serialises subject
/// configuration against snapshot creation, and no queue of its own is needed.
/// Completions are delivered asynchronously on the main queue.
///
@MainActor
final class AccessibilityMonitor {

    // MARK: - Internal properties

    static let shared = AccessibilityMonitor()

    /// How tracking reports, or `nil` while tracking is not configured.
    var fetchType: AccessibilityFetchType? {
        return configuration?.fetchType
    }

    /// Whether tracking is configured with at least one feature.
    var isTracking: Bool {
        return !(configuration?.objects.isEmpty ?? true)
    }

    ///
    /// Bumped on every reconfiguration, so a snapshot in flight can tell
    /// whether the configuration it was taken under is still the current
    /// one, and the kit can tell when its transformed values go stale.
    ///
    private(set) var configurationGeneration = 0

    // MARK: - Private properties

    private var configuration: AccessibilityTrackingConfiguration? {
        didSet { configurationDidChange() }
    }
    /// The app's observations, in the order they were registered.
    private var completions = [(id: Int, state: ObservationState, completion: (AccessibilitySnapshot) -> Void)]()
    private var nextObservationID = 0
    private var snapshotObservers = [WeakSnapshotObserver]()
    private var subjects = [Subject]()
    private var history = AccessibilitySessionHistory()
    private let notificationCenter: NotificationCenter
    private let readState: AccessibilityStateReader
    private let launchDate: Date?

    // MARK: - Lifecycle

    ///
    /// - Parameters:
    ///   - notificationCenter: Where the features' change notifications are posted.
    ///   - readState: How a feature's current state is read. Tests supply
    ///     their own, so values can change on cue.
    ///   - launchDate: When the app launched, so history started soon after
    ///     reads as "at launch".
    ///
    init(
        notificationCenter: NotificationCenter = .default,
        readState: @escaping AccessibilityStateReader = AccessibilityObjectFactory.readState,
        launchDate: Date? = ProcessLaunch.date
    ) {
        self.notificationCenter = notificationCenter
        self.readState = readState
        self.launchDate = launchDate
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
        DispatchQueue.main.async { state.markKept() }

        takeAndDeliverSnapshot(toObservations: [id], observers: [], reason: .registration)

        return observation
    }

    ///
    /// Registers an additional, weakly held snapshot listener, without
    /// touching the app's observations. It receives the current snapshot on
    /// registration if tracking is configured, every change under a
    /// continuous configuration, and a refresh each time tracking is
    /// configured, which is how a listener registered first is filled in.
    /// Registering an observer that is already registered does nothing, and
    /// hands it nothing.
    ///
    func addSnapshotObserver(_ observer: AccessibilitySnapshotObserver) {
        pruneSnapshotObservers()
        guard !snapshotObservers.contains(where: { $0.observer === observer }) else { return }

        let entry = WeakSnapshotObserver(observer: observer)
        snapshotObservers.append(entry)
        takeAndDeliverSnapshot(toObservations: [], observers: [entry], reason: .registration)
    }

    ///
    /// The system's values for a feature this session, oldest first, before
    /// any transform, up to `mark` — a snapshot's ``AccessibilitySnapshot/historyMark`` — when given.
    ///
    func history(for type: AccessibilityType, upTo mark: Int? = nil) -> [AccessibilityHistoryEntry] {
        let entries = history.entries(for: type)
        guard let mark else { return entries }
        return entries.filter { $0.sequence < mark }
    }

    /// The configured tracking objects, empty while tracking is not configured.
    var trackingObjects: [AccessibilityTrackingObject] {
        return configuration?.objects ?? []
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor: AccessibilityObserver {

    ///
    /// The system's value is recorded on every change, whoever is listening,
    /// so the session history is complete whenever the kit is opened later.
    /// It is the state the subject already read, so no app code runs for it.
    ///
    func accessibilityStateDidChange(_ state: AccessibilityState) {
        history.record(state, at: Date())

        guard configuration?.fetchType == .continuous else { return }
        pruneSnapshotObservers()
        takeAndDeliverSnapshot(toObservations: completions.map(\.id), observers: snapshotObservers, reason: .change)
    }
}

// MARK: - Private methods

private extension AccessibilityMonitor {

    ///
    /// Subscribes to the new features, carries their history over, and hands
    /// snapshot observers — the kit's UI — the newly configured features
    /// without waiting for a change, so a screen never keeps showing rows for
    /// features that are no longer tracked, nor stays empty because its first
    /// snapshot was dropped. The app's own observations are left alone:
    /// reconfiguring emits no snapshot to them.
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
        let atLaunch = ProcessLaunch.isPrewarmed
            || launchDate.map { now.timeIntervalSince($0) < ProcessLaunch.window } ?? true
        history.track(Array(states.values), at: now, atLaunch: atLaunch)

        pruneSnapshotObservers()
        takeAndDeliverSnapshot(
            toObservations: [],
            observers: snapshotObservers,
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
    /// configured. Transforms run while it is taken, and one that
    /// reconfigures tracking leaves the snapshot stale, so it is then
    /// discarded rather than returned.
    ///
    func takeConfiguredSnapshot(readState: AccessibilityStateReader? = nil) -> (AccessibilitySnapshot, Int)? {
        guard let configuration else { return nil }

        let generation = configurationGeneration
        var snapshot = AccessibilitySnapshot(trackingObjects: configuration.objects, readState: readState ?? self.readState)
        guard generation == configurationGeneration else { return nil }
        snapshot.historyMark = history.mark
        return (snapshot, generation)
    }

    ///
    /// Takes a snapshot for these recipients and delivers it. A snapshot
    /// nobody is registered to receive is not taken: whoever registers later
    /// is handed a snapshot of their own.
    ///
    func takeAndDeliverSnapshot(
        toObservations ids: [Int],
        observers: [WeakSnapshotObserver],
        reason: SnapshotDeliveryReason,
        readState: AccessibilityStateReader? = nil
    ) {
        guard !ids.isEmpty || observers.contains(where: { $0.observer != nil }) else { return }
        guard let (snapshot, generation) = takeConfiguredSnapshot(readState: readState) else { return }

        deliver(snapshot, takenUnder: generation, toObservations: ids, observers: observers, reason: reason)
    }

    ///
    /// Delivers a snapshot on a later main-queue turn, never inside the call
    /// that scheduled it, to the observations and then to the observers. Both
    /// are captured now, so a snapshot goes only to whoever was registered
    /// when it was taken.
    ///
    /// Each recipient is checked as it is reached. Once tracking has been
    /// reconfigured since the snapshot was taken — even by an earlier
    /// recipient of this same delivery — nobody further receives it, and an
    /// observation that has ended since is skipped: it is never called again.
    ///
    func deliver(
        _ snapshot: AccessibilitySnapshot,
        takenUnder generation: Int,
        toObservations ids: [Int],
        observers: [WeakSnapshotObserver],
        reason: SnapshotDeliveryReason
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            for id in ids {
                guard self.configurationGeneration == generation else { return }
                guard let entry = self.completions.first(where: { $0.id == id }), !entry.state.isCancelled else { continue }
                entry.completion(snapshot)
            }

            for entry in observers {
                guard self.configurationGeneration == generation else { return }
                entry.observer?.accessibilitySnapshotDidChange(snapshot, reason: reason)
            }
        }
    }

    func pruneSnapshotObservers() {
        snapshotObservers.removeAll(where: { $0.observer == nil })
    }
}

// MARK: - Weak snapshot observer

///
/// Snapshot observers are held weakly: the view model holds its monitor, so
/// holding it back would be a cycle, and a dismissed screen must stop being
/// told anything.
///
private struct WeakSnapshotObserver {

    weak var observer: AccessibilitySnapshotObserver?
}
