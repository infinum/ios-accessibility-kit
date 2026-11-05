//
//  AccessibilityMonitor.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

///
/// Holds the tracking configuration, owns a subject per tracked feature, and
/// delivers snapshots to the registered observation.
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
            generation += 1
            guard let configuration = configuration else { return }
            configureSubjects(for: configuration)
        }
    }
    private var snapshotChangeHandler: ((AccessibilitySnapshot) -> Void)? {
        didSet { generation += 1 }
    }
    /// Bumped whenever the configuration or the completion is replaced, so a
    /// snapshot in flight can tell whether both are still the ones it was
    /// taken for.
    private var generation = 0
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
        createSnapshot(isInitial: true)
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor: AccessibilityObserver {

    func accessibilityStateDidChange(_ state: AccessibilityState) {
        createSnapshot()
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

    func createSnapshot(isInitial: Bool = false) {
        // Without a completion the snapshot could never be delivered, since
        // registering one bumps the generation, so it is not taken at all.
        guard
            let configuration = configuration,
            let handler = snapshotChangeHandler,
            (configuration.fetchType == .continuous || isInitial)
        else { return }

        let generation = self.generation
        let snapshot = AccessibilitySnapshot(
            trackingObjects: configuration.objects
        )
        // Delivered asynchronously so a completion never runs inside the
        // caller's own call to `observeAccessibilityTracking(completion:)`.
        // A snapshot whose configuration or completion has been replaced by
        // the time it lands is dropped: a replaced completion is never called
        // again, and its replacement receives only snapshots taken for it.
        DispatchQueue.main.async { [weak self] in
            guard self?.generation == generation else { return }
            handler(snapshot)
        }
    }
}
