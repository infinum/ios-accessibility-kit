//
//  AssistiveTouchAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct AssistiveTouchAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isAssistiveTouchRunning: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isAssistiveTouchRunning: @escaping @MainActor () -> Bool = { UIAccessibility.isAssistiveTouchRunning }) {
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
