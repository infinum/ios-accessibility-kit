//
//  ButtonShapesAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

@available(iOS 14.0, *)
final class ButtonShapesAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ButtonShapesAccessibilityObject())
    }
}

// MARK: - AccessibilityState

@available(iOS 14.0, *)
extension ButtonShapesAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .buttonShapes }

    public var enabled: Bool { UIAccessibility.buttonShapesEnabled }
}
