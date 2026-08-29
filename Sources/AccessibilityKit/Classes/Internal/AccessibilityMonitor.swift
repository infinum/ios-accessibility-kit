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
            guard let configuration = configuration else { return }
            configureSubjects(for: configuration)
        }
    }
    private var snapshotChangeHandler: ((AccessibilitySnapshot) -> Void)?
    private var snapshotObservers = [WeakSnapshotObserver]()
    private var subjects = [Subject]()
    private let notificationCenter: NotificationCenter

    // MARK: - Lifecycle

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Public methods

    func currentAccessibilitySnapshot(for objects: [AccessibilityTrackingObject]) -> AccessibilitySnapshot {
        return AccessibilitySnapshot(trackingObjects: objects)
    }

    func configureAccessibilityTracking(with configuration: AccessibilityTrackingConfiguration) {
        self.configuration = configuration
    }

    func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) {
        snapshotChangeHandler = completion

        guard let snapshot = configuredSnapshot() else { return }
        // Delivered asynchronously so the completion never runs inside the
        // caller's own registration call, and captured here so the snapshot
        // lands in this completion even if it is replaced while in flight.
        DispatchQueue.main.async {
            completion(snapshot)
        }
    }

    ///
    /// Registers an additional, weakly held snapshot listener. It receives
    /// the current snapshot on registration and every change thereafter,
    /// without touching the completion registered through
    /// ``observeAccessibilityTracking(completion:)``.
    ///
    func addSnapshotObserver(_ observer: AccessibilitySnapshotObserver) {
        pruneSnapshotObservers()
        guard !snapshotObservers.contains(where: { $0.observer === observer }) else { return }
        snapshotObservers.append(WeakSnapshotObserver(observer: observer))

        guard let snapshot = configuredSnapshot() else { return }
        DispatchQueue.main.async { [weak observer] in
            observer?.accessibilitySnapshotDidChange(snapshot)
        }
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor: AccessibilityObserver {

    func accessibilityStateDidChange(_ state: AccessibilityState) {
        guard
            configuration?.fetchType == .continuous,
            let snapshot = configuredSnapshot()
        else { return }

        pruneSnapshotObservers()
        // The completion and observers are captured here, at scheduling time,
        // so a snapshot lands with whoever was registered when the change
        // occurred — never with a replacement registered while in flight.
        let handler = snapshotChangeHandler
        let observers = snapshotObservers
        DispatchQueue.main.async {
            handler?(snapshot)
            observers.forEach { $0.observer?.accessibilitySnapshotDidChange(snapshot) }
        }
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
