//
//  DifferentiateWithoutColorAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct DifferentiateWithoutColorAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let shouldDifferentiateWithoutColor: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(shouldDifferentiateWithoutColor: @escaping @MainActor () -> Bool = { UIAccessibility.shouldDifferentiateWithoutColor }) {
        self.shouldDifferentiateWithoutColor = shouldDifferentiateWithoutColor
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .differentiateWithoutColor
    }

    var name: String {
        return "Differentiate Without Color"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.differentiateWithoutColorDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(shouldDifferentiateWithoutColor()),
            customIdentifier: customIdentifier
        )
    }
}
