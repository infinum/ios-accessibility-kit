//
//  SpeakScreenAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class SpeakScreenAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .speakScreen }

    public var enabled: Bool { UIAccessibility.isSpeakScreenEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.speakScreenStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: SpeakScreenAccessibilityObject())
    }
}
