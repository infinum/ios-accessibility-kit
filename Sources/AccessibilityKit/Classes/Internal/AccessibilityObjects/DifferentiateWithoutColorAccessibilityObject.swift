//
//  DifferentiateWithoutColorAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class DifferentiateWithoutColorAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .differentiateWithoutColor }

    public var enabled: Bool { UIAccessibility.shouldDifferentiateWithoutColor }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.differentiateWithoutColorDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: DifferentiateWithoutColorAccessibilityObject())
    }
}
