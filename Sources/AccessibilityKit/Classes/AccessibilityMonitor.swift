//
//  AccessibilityMonitor.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class AccessibilityMonitor {

    // MARK: - Public methods

    public static let `default` = AccessibilityMonitor()

    // MARK: - Private properties

    private let concurrentQueue = DispatchQueue(
        label: "com.infinum.accessibilityKit.accessibilityMonitor.queue",
        attributes: .concurrent
    )
    private var configuration: AccessibilityTrackingConfiguration? {
        didSet {
            clearSnapshots()
            guard let configuration = configuration else { return }
            configureSubjects(for: configuration)
        }
    }
    private var snapshotChangeHandler: ((AccessibilitySnapshot) -> Void)?
    private var snapshots = [AccessibilitySnapshot]()
    private var subjects = [Subject]()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Public methods

    func configureTracking(with configuration: AccessibilityTrackingConfiguration) {
        self.configuration = configuration
    }

    public func observeTrackingChanges(completion: @escaping (AccessibilitySnapshot) -> Void) {
        snapshotChangeHandler = completion
        publishSnapshotChanges()
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor: AccessibilityObserver {

    func accessibilityStateDidChange(_ state: AccessibilityState) {
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            guard let configuration = self.configuration, configuration.fetchType == .continuous else { return }
            self.snapshots.append(AccessibilitySnapshot(trackingObjects: configuration.objects))
            self.publishSnapshotChanges()
        }
    }
}

// MARK: - Private methods

private extension AccessibilityMonitor {

    func configureSubjects(for configuration: AccessibilityTrackingConfiguration) {
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            self.subjects.forEach { $0.removeObservers() }
            self.subjects = Set(configuration.objects.map(\.type))
                .map(AccessibilitySubject.init(type: ))
            self.subjects.forEach { $0.addObserver(self) }
        }
    }

    func publishSnapshotChanges() {
        guard let snapshot = snapshots.last else { return }
        snapshotChangeHandler?(snapshot)
    }

    func clearSnapshots() {
        snapshots = []
        snapshotChangeHandler = nil
    }
}
