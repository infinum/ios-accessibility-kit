//
//  SpeakScreenAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct SpeakScreenAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .speakScreen
    }

    var name: String {
        return "Speak Screen"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.speakScreenStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isSpeakScreenEnabled),
            customIdentifier: customIdentifier
        )
    }
}
