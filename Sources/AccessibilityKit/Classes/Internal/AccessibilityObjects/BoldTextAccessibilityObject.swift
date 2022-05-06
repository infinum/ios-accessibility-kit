//
//  BoldTextAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct BoldTextAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .boldText
    }

    var name: String {
        return "Bold Text"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.boldTextStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isBoldTextEnabled),
            customIdentifier: customIdentifier
        )
    }
}
