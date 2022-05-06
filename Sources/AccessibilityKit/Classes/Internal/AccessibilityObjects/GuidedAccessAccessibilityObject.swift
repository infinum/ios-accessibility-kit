//
//  GuidedAccessAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct GuidedAccessAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .guidedAccess
    }

    var name: String {
        return "Guided Access"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.guidedAccessStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isGuidedAccessEnabled),
            customIdentifier: customIdentifier
        )
    }
}
