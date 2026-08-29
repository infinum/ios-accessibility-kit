//
//  AccessibilityKit.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

import UIKit
import SwiftUI

public final class AccessibilityKit {

    // MARK: - Public properties

    public static let shared = AccessibilityKit()

    // MARK: - Private properties

    private let monitor: AccessibilityMonitor

    // MARK: - Lifecycle

    init(monitor: AccessibilityMonitor = .shared) {
        self.monitor = monitor
    }

    // MARK: - Public methods

    public func currentAccessibilitySnapshot(for objects: [AccessibilityTrackingObject]) -> AccessibilitySnapshot {
        return monitor.currentAccessibilitySnapshot(for: objects)
    }

    public func configureAccessibilityTracking(with configuration: AccessibilityTrackingConfiguration) {
        monitor.configureAccessibilityTracking(with: configuration)
    }

    public func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) {
        monitor.observeAccessibilityTracking(completion: completion)
    }

    public func presentAccessibilityMonitor(on viewController: UIViewController) {
        let monitorViewController = UIHostingController(rootView: AccessibilityMonitorView(onDismiss: { viewController.dismiss(animated: true) }))

        viewController.present(
            monitorViewController,
            animated: true,
            completion: nil
        )
    }
}
