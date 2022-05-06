//
//  VideoAutoplayAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct VideoAutoplayAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .videoAutoplay
    }

    var name: String {
        return "Video Autoplay"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.videoAutoplayStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(UIAccessibility.isVideoAutoplayEnabled),
            customIdentifier: customIdentifier
        )
    }
}
