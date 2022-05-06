//
//  AssistiveTouchAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct AssistiveTouchAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .assistiveTouch
    }

    var name: String {
        return "Assistive Touch"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.assistiveTouchStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isAssistiveTouchRunning),
            customIdentifier: customIdentifier
        )
    }
}
