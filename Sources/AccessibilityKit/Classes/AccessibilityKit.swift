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

    public func configureTracking(with configuration: AccessibilityTrackingConfiguration) {
        AccessibilityMonitor.default.configureTracking(with: configuration)
    }

    public func observeTrackingChanges(completion: @escaping (AccessibilitySnapshot) -> Void) {
        AccessibilityMonitor.default.observeTrackingChanges(completion: completion)
    }
}
