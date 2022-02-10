//
//  SpeakSelectionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class SpeakSelectionAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.speakSelectionStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: SpeakSelectionAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension SpeakSelectionAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .speakSelection }

    public var enabled: Bool { UIAccessibility.isSpeakSelectionEnabled }
}
