//
//  GuidedAccessAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct GuidedAccessAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isGuidedAccessEnabled: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isGuidedAccessEnabled: @escaping @MainActor () -> Bool = { UIAccessibility.isGuidedAccessEnabled }) {
        self.isGuidedAccessEnabled = isGuidedAccessEnabled
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .guidedAccess
    }

    var name: String {
        return "Guided Access"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.guidedAccessStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isGuidedAccessEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
