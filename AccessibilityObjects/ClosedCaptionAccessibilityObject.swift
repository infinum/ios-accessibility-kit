//
//  ClosedCaptionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class ClosedCaptionAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.closedCaptioningStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ClosedCaptionAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension ClosedCaptionAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .closedCaption }

    public var enabled: Bool { UIAccessibility.isClosedCaptioningEnabled }
}
