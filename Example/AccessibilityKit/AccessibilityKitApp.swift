//
//  AccessibilityKitApp.swift
//  Example
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI
import AccessibilityKit

@main
struct AccessibilityKitApp: App {
    init() {
        do {
            let configuration = try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .boldText),
                    AccessibilityTrackingObject(type: .buttonShapes),
                    AccessibilityTrackingObject(type: .reduceMotion),
                    AccessibilityTrackingObject(type: .voiceOver),
                    AccessibilityTrackingObject(type: .fontScale)
                ]
            )
            AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
        } catch {
            // A duplicate accessibility type is a mistake in the configuration
            // above, not a runtime condition, so surface it during development.
            assertionFailure("Invalid accessibility tracking configuration: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AccessibilityKitView()
        }
    }
}
