//
//  SwitchControlAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class SwitchControlAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .switchControl }

    public var enabled: Bool { UIAccessibility.isSwitchControlRunning }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.switchControlStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: SwitchControlAccessibilityObject())
    }
}
