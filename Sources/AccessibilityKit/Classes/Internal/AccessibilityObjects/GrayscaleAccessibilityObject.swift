//
//  GrayscaleAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct GrayscaleAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isGrayscaleEnabled: () -> Bool

    // MARK: - Lifecycle

    init(isGrayscaleEnabled: @escaping () -> Bool = { UIAccessibility.isGrayscaleEnabled }) {
        self.isGrayscaleEnabled = isGrayscaleEnabled
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .grayscale
    }

    var name: String {
        return "Grayscale"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.grayscaleStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isGrayscaleEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
