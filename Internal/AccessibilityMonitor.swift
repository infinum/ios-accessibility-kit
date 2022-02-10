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

    private var objects = [AccessibilityObject]()

    private var snapshotsCompletionHandler: ((AccessibilitySnapshot) -> Void)?

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Public methods

    func configureMonitoring(for types: [AccessibilityType]) {
        objects.forEach { $0.removeObservers() }
        objects = types.compactMap(AccessibilityObjectFactory.object(for:))
        objects.forEach { $0.addObserver(self) }
    }

    public func observeChanges(completion: @escaping (AccessibilitySnapshot) -> Void) {
        snapshotsCompletionHandler = completion
        snapshotsCompletionHandler?(AccessibilitySnapshot(states: objects))
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityMonitor {

    func accessibilityStateDidChange(_ accessibilityState: AccessibilityState) {
        guard let oldObject = objects.first(where: { $0.type == accessibilityState.type }) else { return }

        oldObject.removeObserver(self)
        objects.removeAll(where: { $0.type == oldObject.type })

        guard let newObject = AccessibilityObjectFactory.object(for: accessibilityState.type) else { return }

        newObject.addObserver(self)
        objects.append(newObject)

        snapshotsCompletionHandler?(AccessibilitySnapshot(states: objects))
    }
}
