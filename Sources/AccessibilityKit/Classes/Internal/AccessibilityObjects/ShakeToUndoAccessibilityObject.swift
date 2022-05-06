//
//  ShakeToUndoAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct ShakeToUndoAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .shakeToUndo
    }

    var name: String {
        return "Shake To Undo"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.shakeToUndoDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isShakeToUndoEnabled),
            customIdentifier: customIdentifier
        )
    }
}
