//
//  MonoAudioAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class MonoAudioAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .monoAudio }

    public var enabled: Bool { UIAccessibility.isMonoAudioEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.monoAudioStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: MonoAudioAccessibilityObject())
    }
}
