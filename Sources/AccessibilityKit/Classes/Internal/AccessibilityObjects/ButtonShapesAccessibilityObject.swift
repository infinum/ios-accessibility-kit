//
//  ButtonShapesAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@available(iOS 14.0, *)
struct ButtonShapesAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .buttonShapes
    }

    var name: String {
        return "Button Shapes"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.buttonShapesEnabledStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.buttonShapesEnabled),
            customIdentifier: customIdentifier
        )
    }
}
