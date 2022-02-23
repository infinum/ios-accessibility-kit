//
//  AssistiveTouchAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class AssistiveTouchAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .assistiveTouch }

    public var enabled: Bool { UIAccessibility.isAssistiveTouchRunning }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.assistiveTouchStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: AssistiveTouchAccessibilityObject())
    }
}
