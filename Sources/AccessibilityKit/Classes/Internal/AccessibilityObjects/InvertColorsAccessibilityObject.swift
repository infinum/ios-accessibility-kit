//
//  InvertColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct InvertColorsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .invertColors
    }

    var name: String {
        return "Invert Colors"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.invertColorsStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isInvertColorsEnabled),
            customIdentifier: customIdentifier
        )
    }
}
