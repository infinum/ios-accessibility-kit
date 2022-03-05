//
//  DarkSystemColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct DarkerSystemColorsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .darkerSystemColors
    }

    var name: String {
        return "Darker System Colors"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.darkerSystemColorsStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isDarkerSystemColorsEnabled),
            customIdentifier: customIdentifier
        )
    }
}
