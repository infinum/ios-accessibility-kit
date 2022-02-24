//
//  SpeakSelectionAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class SpeakSelectionAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.speakSelectionStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .speakSelection,
                value: .flag(UIAccessibility.isSpeakSelectionEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
