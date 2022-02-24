//
//  GuidedAccessAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class GuidedAccessAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.guidedAccessStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .guidedAccess,
                value: .flag(UIAccessibility.isGuidedAccessEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
