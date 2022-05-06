//
//  OnOffSwitchLabelsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct OnOffSwitchLabelsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .onOffSwitchLabels
    }

    var name: String {
        return "On/Off Switch Labels"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.onOffSwitchLabelsDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isOnOffSwitchLabelsEnabled),
            customIdentifier: customIdentifier
        )
    }
}
