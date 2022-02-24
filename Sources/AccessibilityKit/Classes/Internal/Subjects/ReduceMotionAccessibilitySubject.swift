//
//  ReduceMotionAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class ReduceMotionAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.reduceMotionStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .reduceMotion,
                value: .flag(UIAccessibility.isReduceMotionEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
