//
//  MonoAudioAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class MonoAudioAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.monoAudioStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .monoAudio,
                value: .flag(UIAccessibility.isMonoAudioEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
