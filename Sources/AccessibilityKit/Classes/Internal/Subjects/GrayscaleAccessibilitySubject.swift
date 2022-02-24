//
//  GrayscaleAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class GrayscaleAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.grayscaleStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .grayscale,
                value: .flag(UIAccessibility.isGrayscaleEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
