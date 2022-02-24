//
//  SwitchControlAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class SwitchControlAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.switchControlStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .switchControl,
                value: .flag(UIAccessibility.isSwitchControlRunning),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
