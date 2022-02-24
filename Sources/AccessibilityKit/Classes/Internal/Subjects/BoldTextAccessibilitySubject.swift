//
//  BoldTextAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class BoldTextAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.boldTextStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .boldText,
                value: .flag(UIAccessibility.isBoldTextEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
