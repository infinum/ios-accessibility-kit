//
//  GuidedAccessAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class GuidedAccessAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .guidedAccess }

    public var enabled: Bool { UIAccessibility.isGuidedAccessEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.guidedAccessStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: GuidedAccessAccessibilityObject())
    }
}
