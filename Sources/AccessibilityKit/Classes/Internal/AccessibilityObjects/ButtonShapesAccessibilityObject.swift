//
//  ButtonShapesAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct ButtonShapesAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let buttonShapesEnabled: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(buttonShapesEnabled: @escaping @MainActor () -> Bool = { UIAccessibility.buttonShapesEnabled }) {
        self.buttonShapesEnabled = buttonShapesEnabled
    }

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
            value: .flag(buttonShapesEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
