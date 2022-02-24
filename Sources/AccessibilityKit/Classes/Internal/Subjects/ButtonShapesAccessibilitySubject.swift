//
//  ButtonShapesAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@available(iOS 14.0, *)
final class ButtonShapesAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .buttonShapes,
                value: .flag(UIAccessibility.buttonShapesEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
