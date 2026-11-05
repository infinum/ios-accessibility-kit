//
//  AccessibilityMonitor.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

///
/// Holds the tracking configuration, owns a subject per tracked feature, and
/// delivers snapshots to the registered observation and to any snapshot
/// observers — the accessibility monitor UI — which are held weakly and never
/// disturb the observation.
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

    // MARK: - Private properties

    private var configuration: AccessibilityTrackingConfiguration? {
        didSet {
            configurationGeneration += 1
            guard let configuration = configuration else { return }
            configureSubjects(for: configuration)
            refreshSnapshotObservers()
        }
    }
    private var snapshotChangeHandler: ((AccessibilitySnapshot) -> Void)? {
        didSet { completionGeneration += 1 }
    }
    /// Bumped on every reconfiguration, so a snapshot in flight can tell
    /// whether the configuration it was taken under is still the current one.
    private var configurationGeneration = 0
    /// Bumped whenever the completion is replaced, so a snapshot in flight can
    /// tell whether the completion it was taken for is still registered.
    /// Snapshot observers do not look at it: replacing the app's completion
    /// leaves them alone.
    private var completionGeneration = 0
    private var snapshotObservers = [WeakSnapshotObserver]()
    private var subjects = [Subject]()
    private let notificationCenter: NotificationCenter

    // MARK: - Lifecycle

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Internal methods

    func currentAccessibilitySnapshot(for objects: [AccessibilityTrackingObject]) -> AccessibilitySnapshot {
        return AccessibilitySnapshot(trackingObjects: objects)
    }

    func configureAccessibilityTracking(with configuration: AccessibilityTrackingConfiguration) {
        self.configuration = configuration
    }

    func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) {
        snapshotChangeHandler = completion
        deliverLater(toCompletion: completion, observers: [])
    }

    ///
    /// Registers an additional, weakly held snapshot listener. It receives
    /// the current snapshot on registration, every change under a
    /// continuous configuration, and a refresh on each reconfiguration,
    /// without touching the completion registered through
    /// ``observeAccessibilityTracking(completion:)``. Registering an
    /// observer that is already registered does nothing, and hands it
    /// nothing.
    ///
    func addSnapshotObserver(_ observer: AccessibilitySnapshotObserver) {
        pruneSnapshotObservers()
        guard !snapshotObservers.contains(where: { $0.observer === observer }) else { return }

        let entry = WeakSnapshotObserver(observer: observer)
        snapshotObservers.append(entry)
        deliverLater(toCompletion: nil, observers: [entry])
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor: AccessibilityObserver {

    func accessibilityStateDidChange(_ state: AccessibilityState) {
        guard configuration?.fetchType == .continuous else { return }

        // A snapshot nobody is registered to receive is not taken: whoever
        // registers later is handed a snapshot of their own.
        pruneSnapshotObservers()
        guard snapshotChangeHandler != nil || !snapshotObservers.isEmpty else { return }

        deliverLater(toCompletion: snapshotChangeHandler, observers: snapshotObservers)
    }
}

// MARK: - Private methods

private extension AccessibilityMonitor {

    func configureSubjects(for configuration: AccessibilityTrackingConfiguration) {
        // The old subjects are released by the assignment below, and a
        // released subject takes its observer list and its notification
        // registration with it.
        subjects = Set(configuration.objects.map(\.type))
            .map { AccessibilitySubject(type: $0, notificationCenter: notificationCenter) }
        subjects.forEach { $0.addObserver(self) }
    }

    func configuredSnapshot() -> AccessibilitySnapshot? {
        guard let configuration = configuration else { return nil }

        return AccessibilitySnapshot(trackingObjects: configuration.objects)
    }

    ///
    /// Takes a snapshot of the configured features, if tracking is
    /// configured, and delivers it on a later main-queue turn, never inside
    /// the call that scheduled it, to `completion` and then to `observers`.
    /// Both are captured now, so a snapshot goes only to whoever was
    /// registered when it was taken.
    ///
    /// Each recipient is checked as it is reached. Once tracking has been
    /// reconfigured since the snapshot was taken — even by an earlier
    /// recipient of this same delivery — nobody further receives it, and the
    /// completion is skipped once it has been replaced: a replaced completion
    /// is never called again.
    ///
    func deliverLater(
        toCompletion completion: ((AccessibilitySnapshot) -> Void)?,
        observers: [WeakSnapshotObserver]
    ) {
        // Recorded before the snapshot is taken: transforms run while it is,
        // and one that reconfigures tracking or replaces the completion must
        // leave this snapshot stale rather than go unnoticed.
        let configurationGeneration = self.configurationGeneration
        let completionGeneration = self.completionGeneration
        guard let snapshot = configuredSnapshot() else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self, self.configurationGeneration == configurationGeneration else { return }

            if let completion, self.completionGeneration == completionGeneration {
                completion(snapshot)
            }

            for entry in observers {
                guard self.configurationGeneration == configurationGeneration else { return }
                entry.observer?.accessibilitySnapshotDidChange(snapshot)
            }
        }
    }

    ///
    /// Hands snapshot observers — the accessibility monitor UI — the newly
    /// configured features without waiting for a change, so the screen never
    /// keeps showing rows for features that are no longer tracked, nor stays
    /// empty because its first snapshot was dropped. The app's own completion
    /// is left alone: reconfiguring emits no snapshot to it.
    ///
    func refreshSnapshotObservers() {
        pruneSnapshotObservers()
        guard !snapshotObservers.isEmpty else { return }

        deliverLater(toCompletion: nil, observers: snapshotObservers)
    }

    func pruneSnapshotObservers() {
        snapshotObservers.removeAll(where: { $0.observer == nil })
    }
}

// MARK: - Weak snapshot observer

///
/// Snapshot observers are held weakly: the monitor outlives the views
/// listening to it, and must not keep them alive.
///
private struct WeakSnapshotObserver {

    weak var observer: AccessibilitySnapshotObserver?
}
