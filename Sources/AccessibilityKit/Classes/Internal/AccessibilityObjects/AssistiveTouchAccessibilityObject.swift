//
//  AssistiveTouchAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct AssistiveTouchAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isAssistiveTouchRunning: () -> Bool

    // MARK: - Lifecycle

    init(isAssistiveTouchRunning: @escaping () -> Bool = { UIAccessibility.isAssistiveTouchRunning }) {
        self.isAssistiveTouchRunning = isAssistiveTouchRunning
    }

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
            value: .flag(isAssistiveTouchRunning()),
            customIdentifier: customIdentifier
        )
    }
}
