//
//  SpeakSelectionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct SpeakSelectionAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isSpeakSelectionEnabled: () -> Bool

    // MARK: - Lifecycle

    init(isSpeakSelectionEnabled: @escaping () -> Bool = { UIAccessibility.isSpeakSelectionEnabled }) {
        self.isSpeakSelectionEnabled = isSpeakSelectionEnabled
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .speakSelection
    }

    var name: String {
        return "Speak Selection"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.speakSelectionStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isSpeakSelectionEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
