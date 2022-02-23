//
//  ButtonShapesAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@available(iOS 14.0, *)
final class ButtonShapesAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .buttonShapes }

    public var enabled: Bool { UIAccessibility.buttonShapesEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ButtonShapesAccessibilityObject())
    }
}
