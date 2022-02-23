//
//  ClosedCaptionAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class ClosedCaptionAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .closedCaption }

    public var enabled: Bool { UIAccessibility.isClosedCaptioningEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.closedCaptioningStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: ClosedCaptionAccessibilityObject())
    }
}
