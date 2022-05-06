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
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            subjects.forEach { $0.removeObservers() }
            subjects = Set(configuration.objects.map(\.type))
                .map(AccessibilitySubject.init(type: ))
            subjects.forEach { $0.addObserver(self) }
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
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            snapshots.append(snapshot)
            DispatchQueue.main.async {
                snapshotChangeHandler?(snapshot)
            }
        }
    }

    func clearSnapshots() {
        snapshots = []
        snapshotChangeHandler = nil
    }
}
