//
//  AssistiveTouchAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class AssistiveTouchAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.assistiveTouchStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: AssistiveTouchAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension AssistiveTouchAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .assistiveTouch }

    public var enabled: Bool { UIAccessibility.isAssistiveTouchRunning }
}
