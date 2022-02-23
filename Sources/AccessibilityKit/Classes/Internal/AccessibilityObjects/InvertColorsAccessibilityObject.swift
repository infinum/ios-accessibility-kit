//
//  InvertColorsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class InvertColorsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .invertColors }

    public var enabled: Bool { UIAccessibility.isInvertColorsEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.invertColorsStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: InvertColorsAccessibilityObject())
    }
}
