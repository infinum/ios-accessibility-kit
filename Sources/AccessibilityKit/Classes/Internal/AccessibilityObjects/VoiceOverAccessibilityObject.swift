//
//  VoiceOverAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct VoiceOverAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isVoiceOverRunning: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isVoiceOverRunning: @escaping @MainActor () -> Bool = { UIAccessibility.isVoiceOverRunning }) {
        self.isVoiceOverRunning = isVoiceOverRunning
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .voiceOver
    }

    var name: String {
        return "VoiceOver"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.voiceOverStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isVoiceOverRunning()),
            customIdentifier: customIdentifier
        )
    }

}
