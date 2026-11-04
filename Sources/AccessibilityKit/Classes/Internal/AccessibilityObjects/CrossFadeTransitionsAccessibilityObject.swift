//
//  CrossFadeTransitionsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct CrossFadeTransitionsAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let prefersCrossFadeTransitions: () -> Bool

    // MARK: - Lifecycle

    init(prefersCrossFadeTransitions: @escaping () -> Bool = { UIAccessibility.prefersCrossFadeTransitions }) {
        self.prefersCrossFadeTransitions = prefersCrossFadeTransitions
    }

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
            value: .flag(prefersCrossFadeTransitions()),
            customIdentifier: customIdentifier
        )
    }
}
