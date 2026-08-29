//
//  InvertColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct InvertColorsAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isInvertColorsEnabled: () -> Bool

    // MARK: - Lifecycle

    init(isInvertColorsEnabled: @escaping () -> Bool = { UIAccessibility.isInvertColorsEnabled }) {
        self.isInvertColorsEnabled = isInvertColorsEnabled
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .invertColors
    }

    var name: String {
        return "Invert Colors"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.invertColorsStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isInvertColorsEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
