//
//  CrossFadeTransitionsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@available(iOS 14.0, *)
final class CrossFadeTransitionsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .crossFadeTransitions }

    public var enabled: Bool { UIAccessibility.prefersCrossFadeTransitions }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.prefersCrossFadeTransitionsStatusDidChange)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: CrossFadeTransitionsAccessibilityObject())
    }
}
