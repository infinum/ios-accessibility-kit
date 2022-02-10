//
//  CrossFadeTransitionsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

@available(iOS 14.0, *)
final class CrossFadeTransitionsAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.prefersCrossFadeTransitionsStatusDidChange)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: CrossFadeTransitionsAccessibilityObject())
    }
}

// MARK: - AccessibilityState

@available(iOS 14.0, *)
extension CrossFadeTransitionsAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .crossFadeTransitions }

    public var enabled: Bool { UIAccessibility.prefersCrossFadeTransitions }
}
