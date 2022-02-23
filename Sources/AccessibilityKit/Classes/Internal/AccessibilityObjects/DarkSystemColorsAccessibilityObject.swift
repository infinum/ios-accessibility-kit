//
//  DarkSystemColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class DarkSystemColorsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .darkSystemColors }

    public var enabled: Bool { UIAccessibility.isDarkerSystemColorsEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: DarkSystemColorsAccessibilityObject())
    }
}
