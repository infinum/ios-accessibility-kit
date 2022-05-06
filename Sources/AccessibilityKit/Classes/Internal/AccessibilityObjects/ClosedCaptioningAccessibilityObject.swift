//
//  ClosedCaptioningAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct ClosedCaptioningAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .closedCaptioning
    }

    var name: String {
        return "Closed Captioning"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.closedCaptioningStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isClosedCaptioningEnabled),
            customIdentifier: customIdentifier
        )
    }
}
