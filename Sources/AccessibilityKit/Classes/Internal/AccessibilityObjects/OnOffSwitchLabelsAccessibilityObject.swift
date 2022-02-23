//
//  OnOffSwitchLabelsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class OnOffSwitchLabelsAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .onOffSwitchLabels }

    public var enabled: Bool { UIAccessibility.isOnOffSwitchLabelsEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.onOffSwitchLabelsDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: OnOffSwitchLabelsAccessibilityObject())
    }
}
