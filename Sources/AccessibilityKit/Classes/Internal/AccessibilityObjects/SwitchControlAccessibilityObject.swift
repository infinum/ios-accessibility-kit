//
//  SwitchControlAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct SwitchControlAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .switchControl
    }

    var name: String {
        return "Switch Control"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.switchControlStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isSwitchControlRunning),
            customIdentifier: customIdentifier
        )
    }
}
