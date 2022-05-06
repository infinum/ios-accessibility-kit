//
//  CrossFadeTransitionsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@available(iOS 14.0, *)
struct CrossFadeTransitionsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .crossFadeTransitions
    }

    var name: String {
        return "Cross Fade Transitions"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.prefersCrossFadeTransitionsStatusDidChange
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.prefersCrossFadeTransitions),
            customIdentifier: customIdentifier
        )
    }
}
