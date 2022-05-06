//
//  ReduceTransparencyAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct ReduceTransparencyAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .reduceTransparency
    }

    var name: String {
        return "Reduce Transparency"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.reduceTransparencyStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isReduceTransparencyEnabled),
            customIdentifier: customIdentifier
        )
    }
}
