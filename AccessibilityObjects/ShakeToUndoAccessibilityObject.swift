//
//  ShakeToUndoAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class ShakeToUndoAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .shakeToUndo }

    public var enabled: Bool { UIAccessibility.isShakeToUndoEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.shakeToUndoDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ShakeToUndoAccessibilityObject())
    }
}
