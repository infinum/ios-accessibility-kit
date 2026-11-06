//
//  KitAnnouncer.swift
//  AccessibilityKit
//

import UIKit

/// What the kit says aloud to VoiceOver users.
enum KitAnnouncer {

    /// Queues an announcement behind whatever VoiceOver is already saying.
    @MainActor
    static func announcePolitely(_ message: String) {
        let announcement = NSAttributedString(
            string: message,
            attributes: [.accessibilitySpeechQueueAnnouncement: true]
        )
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
