//
//  GrayscaleAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class GrayscaleAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.grayscaleStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: GrayscaleAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension GrayscaleAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .grayscale }

    public var enabled: Bool { UIAccessibility.isGrayscaleEnabled }
}
