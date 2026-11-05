//
//  SwitchControlAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct SwitchControlAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isSwitchControlRunning: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isSwitchControlRunning: @escaping @MainActor () -> Bool = { UIAccessibility.isSwitchControlRunning }) {
        self.isSwitchControlRunning = isSwitchControlRunning
    }

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
            value: .flag(isSwitchControlRunning()),
            customIdentifier: customIdentifier
        )
    }
}
