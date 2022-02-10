//
//  ReduceTransparencyAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class ReduceTransparencyAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.reduceTransparencyStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ReduceTransparencyAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension ReduceTransparencyAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .reduceTransparency }

    public var enabled: Bool { UIAccessibility.isReduceTransparencyEnabled }
}
