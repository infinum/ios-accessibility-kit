//
//  DarkerSystemColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct DarkerSystemColorsAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isDarkerSystemColorsEnabled: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isDarkerSystemColorsEnabled: @escaping @MainActor () -> Bool = { UIAccessibility.isDarkerSystemColorsEnabled }) {
        self.isDarkerSystemColorsEnabled = isDarkerSystemColorsEnabled
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .darkerSystemColors
    }

    var name: String {
        return "Darker System Colors"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.darkerSystemColorsStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isDarkerSystemColorsEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
