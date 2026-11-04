//
//  MonoAudioAccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import UIKit

struct MonoAudioAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let isMonoAudioEnabled: () -> Bool

    // MARK: - Lifecycle

    init(isMonoAudioEnabled: @escaping () -> Bool = { UIAccessibility.isMonoAudioEnabled }) {
        self.isMonoAudioEnabled = isMonoAudioEnabled
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .monoAudio
    }

    var name: String {
        return "Mono Audio"
    }

    var notificationName: Notification.Name {
        return UIAccessibility.monoAudioStatusDidChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .flag(isMonoAudioEnabled()),
            customIdentifier: customIdentifier
        )
    }
}
