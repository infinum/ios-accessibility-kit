//
//  ClosedCaptioningAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct ClosedCaptioningAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isClosedCaptioningEnabled: () -> Bool

    // MARK: - Lifecycle

    init(isClosedCaptioningEnabled: @escaping () -> Bool = { UIAccessibility.isClosedCaptioningEnabled }) {
        self.isClosedCaptioningEnabled = isClosedCaptioningEnabled
    }

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
            value: .flag(isClosedCaptioningEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
