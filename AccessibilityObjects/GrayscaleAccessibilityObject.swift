//
//  GrayscaleAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class GrayscaleAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .grayscale }

    public var enabled: Bool { UIAccessibility.isGrayscaleEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.grayscaleStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: GrayscaleAccessibilityObject())
    }
}
