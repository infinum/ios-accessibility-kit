//
//  DarkSystemColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class DarkSystemColorsAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: DarkSystemColorsAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension DarkSystemColorsAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .darkSystemColors }

    public var enabled: Bool { UIAccessibility.isDarkerSystemColorsEnabled }
}
