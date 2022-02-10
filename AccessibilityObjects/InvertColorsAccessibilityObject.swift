//
//  InvertColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class InvertColorsAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.invertColorsStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: InvertColorsAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension InvertColorsAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .invertColors }

    public var enabled: Bool { UIAccessibility.isInvertColorsEnabled }
}
