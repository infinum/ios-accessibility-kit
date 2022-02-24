//
//  DarkSystemColorsAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class DarkSystemColorsAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .darkSystemColors,
                value: .flag(UIAccessibility.isDarkerSystemColorsEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
