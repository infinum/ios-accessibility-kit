//
//  VoiceOverAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class VoiceOverAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .voiceOver }

    public var enabled: Bool { UIAccessibility.isVoiceOverRunning }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.voiceOverStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: VoiceOverAccessibilityObject())
    }
}
