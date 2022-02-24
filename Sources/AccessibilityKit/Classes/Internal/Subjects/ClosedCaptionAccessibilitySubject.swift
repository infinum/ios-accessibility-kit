//
//  ClosedCaptionAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class ClosedCaptionAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.closedCaptioningStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .closedCaption,
                value: .flag(UIAccessibility.isClosedCaptioningEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
