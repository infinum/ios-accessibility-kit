//
//  ReduceMotionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class ReduceMotionAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .reduceMotion }

    public var enabled: Bool { UIAccessibility.isReduceMotionEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.reduceMotionStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ReduceMotionAccessibilityObject())
    }
}
