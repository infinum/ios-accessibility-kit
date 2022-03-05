//
//  GrayscaleAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct GrayscaleAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .grayscale
    }

    var name: String {
        return "Grayscale"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.grayscaleStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isGrayscaleEnabled),
            customIdentifier: customIdentifier
        )
    }
}
