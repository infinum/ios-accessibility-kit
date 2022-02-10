//
//  VoiceOverAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class VoiceOverAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.voiceOverStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: VoiceOverAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension VoiceOverAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .voiceOver }

    public var enabled: Bool { UIAccessibility.isVoiceOverRunning }
}
