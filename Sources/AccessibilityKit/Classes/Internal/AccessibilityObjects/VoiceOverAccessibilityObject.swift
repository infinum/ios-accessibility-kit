//
//  VoiceOverAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct VoiceOverAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .voiceOver
    }

    var name: String {
        return "VoiceOver"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.voiceOverStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isVoiceOverRunning),
            customIdentifier: customIdentifier
        )
    }

}
