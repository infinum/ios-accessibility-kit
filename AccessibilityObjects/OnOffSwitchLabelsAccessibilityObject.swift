//
//  OnOffSwitchLabelsAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class OnOffSwitchLabelsAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.onOffSwitchLabelsDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: OnOffSwitchLabelsAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension OnOffSwitchLabelsAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .onOffSwitchLabels }

    public var enabled: Bool { UIAccessibility.isOnOffSwitchLabelsEnabled }
}
