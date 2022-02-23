//
//  VideoAutoplayAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class VideoAutoplayAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    public var type: AccessibilityType { .videoAutoplay }

    public var enabled: Bool { UIAccessibility.isVideoAutoplayEnabled }

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.videoAutoplayStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(state: VideoAutoplayAccessibilityObject())
    }
}
