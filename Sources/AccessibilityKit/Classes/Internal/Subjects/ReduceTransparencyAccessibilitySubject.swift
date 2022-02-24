//
//  ReduceTransparencyAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class ReduceTransparencyAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.reduceTransparencyStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .reduceTransparency,
                value: .flag(UIAccessibility.isReduceTransparencyEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
