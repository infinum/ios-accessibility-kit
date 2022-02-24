//
//  AccessibilityMonitor.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class AccessibilityMonitor: AccessibilityObserver {

    // MARK: - Public methods

    public static let `default` = AccessibilityMonitor()

    // MARK: - Private properties

    private var configuration: AccessibilityTrackingConfiguration? {
        didSet {
            if let configuration = configuration {
                configureSubjects(for: configuration)
            }
            clearSnapshots()
        }
    }
    private var snapshotChangeHandler: ((AccessibilitySnapshot) -> Void)?
    private var snapshots = [AccessibilitySnapshot]()
    private var subjects = [AccessibilitySubject]()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Public methods

    func configureTracking(with configuration: AccessibilityTrackingConfiguration) {
        self.configuration = configuration
    }

    public func observeTrackingChanges(completion: @escaping (AccessibilitySnapshot) -> Void) {
        snapshotChangeHandler = completion
        publishSnapshot()
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor {

    func accessibilityDidChange(_ accessibilityChange: AccessibilityChange) {
        guard let configuration = configuration, configuration.fetchType == .continuous else {
            return
        }

        #warning("TODO: Update state creation.")
        let states = configuration.objects
            .map { AccessibilityState(type: $0.type, customIdentifier: $0.customIdentifier) }

        snapshots.append(AccessibilitySnapshot(states: states))
        publishSnapshot()
    }
}

// MARK: - Private methods

private extension AccessibilityMonitor {

    func configureSubjects(for configuration: AccessibilityTrackingConfiguration) {
        subjects.forEach { $0.removeObservers() }
        subjects = Set(configuration.objects.map(\.type))
            .compactMap(AccessibilitySubjectFactory.object(for:))
        subjects.forEach { $0.addObserver(self) }
    }

    func publishSnapshot() {
        guard let snapshot = snapshots.last else {
            return
        }
        snapshotChangeHandler?(snapshot)
    }

    func clearSnapshots() {
        snapshots = []
        snapshotChangeHandler = nil
    }
}
