//
//  VoiceOverAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class VoiceOverAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.voiceOverStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .voiceOver,
                value: .flag(UIAccessibility.isVoiceOverRunning),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
