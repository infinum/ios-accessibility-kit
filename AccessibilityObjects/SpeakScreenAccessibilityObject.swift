//
//  SpeakScreenAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class SpeakScreenAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.speakScreenStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: SpeakScreenAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension SpeakScreenAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .speakScreen }

    public var enabled: Bool { UIAccessibility.isSpeakScreenEnabled }
}
