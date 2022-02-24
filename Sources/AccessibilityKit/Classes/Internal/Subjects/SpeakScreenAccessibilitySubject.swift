//
//  SpeakScreenAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class SpeakScreenAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.speakScreenStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .speakScreen,
                value: .flag(UIAccessibility.isSpeakScreenEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
