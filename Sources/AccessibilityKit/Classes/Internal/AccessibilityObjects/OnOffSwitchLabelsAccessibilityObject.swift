//
//  OnOffSwitchLabelsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct OnOffSwitchLabelsAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isOnOffSwitchLabelsEnabled: () -> Bool

    // MARK: - Lifecycle

    init(isOnOffSwitchLabelsEnabled: @escaping () -> Bool = { UIAccessibility.isOnOffSwitchLabelsEnabled }) {
        self.isOnOffSwitchLabelsEnabled = isOnOffSwitchLabelsEnabled
    }

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
            value: .flag(isOnOffSwitchLabelsEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
