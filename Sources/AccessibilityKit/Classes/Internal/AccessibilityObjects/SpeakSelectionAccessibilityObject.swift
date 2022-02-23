//
//  SpeakSelectionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class SpeakSelectionAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .speakSelection }

    public var enabled: Bool { UIAccessibility.isSpeakSelectionEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.speakSelectionStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: SpeakSelectionAccessibilityObject())
    }
}
