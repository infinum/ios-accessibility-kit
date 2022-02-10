//
//  ReduceTransparencyAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class ReduceTransparencyAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .reduceTransparency }

    public var enabled: Bool { UIAccessibility.isReduceTransparencyEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.reduceTransparencyStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ReduceTransparencyAccessibilityObject())
    }
}
