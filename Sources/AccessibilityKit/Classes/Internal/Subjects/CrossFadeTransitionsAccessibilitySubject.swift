//
//  CrossFadeTransitionsAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@available(iOS 14.0, *)
final class CrossFadeTransitionsAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.prefersCrossFadeTransitionsStatusDidChange)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .crossFadeTransitions,
                value: .flag(UIAccessibility.prefersCrossFadeTransitions),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
