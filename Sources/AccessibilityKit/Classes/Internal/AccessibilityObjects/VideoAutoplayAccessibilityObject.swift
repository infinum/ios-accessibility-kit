//
//  VideoAutoplayAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

@MainActor
struct VideoAutoplayAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isVideoAutoplayEnabled: @MainActor () -> Bool

    // MARK: - Lifecycle

    init(isVideoAutoplayEnabled: @escaping @MainActor () -> Bool = { UIAccessibility.isVideoAutoplayEnabled }) {
        self.isVideoAutoplayEnabled = isVideoAutoplayEnabled
    }

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
            value: .flag(isVideoAutoplayEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
