//
//  VideoAutoplayAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

final class VideoAutoplayAccessibilityObject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.videoAutoplayStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: VideoAutoplayAccessibilityObject())
    }
}

// MARK: - AccessibilityState

extension VideoAutoplayAccessibilityObject: AccessibilityState {

    public var type: AccessibilityType { .videoAutoplay }

    public var enabled: Bool { UIAccessibility.isVideoAutoplayEnabled }
}
