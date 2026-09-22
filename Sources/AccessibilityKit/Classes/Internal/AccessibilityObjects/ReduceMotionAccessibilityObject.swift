//
//  ReduceMotionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct ReduceMotionAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isReduceMotionEnabled: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isReduceMotionEnabled: @escaping @MainActor () -> Bool = { UIAccessibility.isReduceMotionEnabled }) {
        self.isReduceMotionEnabled = isReduceMotionEnabled
    }

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
            value: .flag(isReduceMotionEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
