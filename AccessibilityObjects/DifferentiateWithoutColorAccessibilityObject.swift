//
//  DifferentiateWithoutColorAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class DifferentiateWithoutColorAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.differentiateWithoutColorDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: DifferentiateWithoutColorAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension DifferentiateWithoutColorAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .differentiateWithoutColor }

    public var enabled: Bool { UIAccessibility.shouldDifferentiateWithoutColor }
}
