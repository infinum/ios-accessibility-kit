//
//  ReduceMotionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct ReduceMotionAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .reduceMotion
    }

    var name: String {
        return "Reduce Motion"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.reduceMotionStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isReduceMotionEnabled),
            customIdentifier: customIdentifier
        )
    }
}
