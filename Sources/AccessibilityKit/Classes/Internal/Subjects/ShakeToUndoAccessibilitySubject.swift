//
//  ShakeToUndoAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class ShakeToUndoAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.shakeToUndoDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .shakeToUndo,
                value: .flag(UIAccessibility.isShakeToUndoEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
