//
//  InvertColorsAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class InvertColorsAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.invertColorsStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .invertColors,
                value: .flag(UIAccessibility.isInvertColorsEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
