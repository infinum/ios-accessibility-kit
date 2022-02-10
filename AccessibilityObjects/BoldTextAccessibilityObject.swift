//
//  BoldTextAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class BoldTextAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.boldTextStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: BoldTextAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension BoldTextAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .boldText }

    public var enabled: Bool { UIAccessibility.isBoldTextEnabled }
}
