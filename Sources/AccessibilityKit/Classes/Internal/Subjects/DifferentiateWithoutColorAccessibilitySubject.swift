//
//  DifferentiateWithoutColorAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class DifferentiateWithoutColorAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.differentiateWithoutColorDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .differentiateWithoutColor,
                value: .flag(UIAccessibility.shouldDifferentiateWithoutColor),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
