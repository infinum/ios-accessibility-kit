//
//  OnOffSwitchLabelsAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class OnOffSwitchLabelsAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.onOffSwitchLabelsDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .onOffSwitchLabels,
                value: .flag(UIAccessibility.isOnOffSwitchLabelsEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
