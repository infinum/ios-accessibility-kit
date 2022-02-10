//
//  ReduceMotionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class ReduceMotionAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.reduceMotionStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ReduceMotionAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension ReduceMotionAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .reduceMotion }

    public var enabled: Bool { UIAccessibility.isReduceMotionEnabled }
}
