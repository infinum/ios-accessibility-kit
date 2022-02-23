//
//  AccessibilityKit.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

public final class AccessibilityKit {

    // MARK: - Public properties

    public static let shared = AccessibilityKit()

    // MARK: - Lifecycle

    private init() { }

    // MARK: - Public methods

    public func configureTracking(for accessibilityTypes: [AccessibilityType]) {
        AccessibilityMonitor.default.configureMonitoring(for: accessibilityTypes)
    }

    public func observeStateChanges(completion: @escaping (AccessibilitySnapshot) -> Void) {
        AccessibilityMonitor.default.observeChanges(completion: completion)
    }
}
