//
//  GuidedAccessAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class GuidedAccessAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.guidedAccessStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: GuidedAccessAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension GuidedAccessAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .guidedAccess }

    public var enabled: Bool { UIAccessibility.isGuidedAccessEnabled }
}
