//
//  VideoAutoplayAccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

final class VideoAutoplayAccessibilitySubject: AccessibilitySubject {

    // MARK: - Lifecycle

    init() {
        super.init(notificationName: UIAccessibility.videoAutoplayStatusDidChangeNotification)
    }

    override func accessibilityDidChange(_ notification: Notification) {
        publish(
            change: AccessibilityChange(
                type: .videoAutoplay,
                value: .flag(UIAccessibility.isVideoAutoplayEnabled),
                timestamp: Date().timeIntervalSince1970
            )
        )
    }
}
