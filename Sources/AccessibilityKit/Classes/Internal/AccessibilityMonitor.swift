//
//  AccessibilityMonitor.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class AccessibilityMonitor {

    // MARK: - Public methods

    static let shared = AccessibilityMonitor()

    // MARK: - Private properties

    private let concurrentQueue = DispatchQueue(
        label: "com.infinum.accessibilityKit.accessibilityMonitor.queue",
        attributes: .concurrent
    )
    private var configuration: AccessibilityTrackingConfiguration? {
        didSet {
            guard let configuration = configuration else { return }
            configureSubjects(for: configuration)
        }
    }
    private var snapshotChangeHandler: ((AccessibilitySnapshot) -> Void)?
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
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // The old subjects are released by the assignment below, and a
            // released subject takes its observer list and its notification
            // registration with it.
            self.subjects = Set(configuration.objects.map(\.type))
                .map { AccessibilitySubject(type: $0, notificationCenter: self.notificationCenter) }
            self.subjects.forEach { $0.addObserver(self) }
        }
    }

    func createSnapshot(isInitial: Bool = false) {
        guard
            let configuration = configuration,
            (configuration.fetchType == .continuous || isInitial)
        else { return }

        let snapshot = AccessibilitySnapshot(
            trackingObjects: configuration.objects
        )
        // Hops the barrier queue so delivery is ordered behind a
        // reconfiguration that is still in flight. The snapshot itself is
        // taken above, before the hop.
        concurrentQueue.async(flags: .barrier) { [weak self] in
            DispatchQueue.main.async {
                self?.snapshotChangeHandler?(snapshot)
            }
        }
    }
}
