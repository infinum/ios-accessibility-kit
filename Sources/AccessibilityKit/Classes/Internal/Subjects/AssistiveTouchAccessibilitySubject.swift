//
//  AssistiveTouchAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class AssistiveTouchAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.assistiveTouchStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .assistiveTouch,
                value: .flag(UIAccessibility.isAssistiveTouchRunning),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
