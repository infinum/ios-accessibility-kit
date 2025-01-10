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
        AccessibilityKit.shared.configureAccessibilityTracking(
            with: AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .boldText),
                    AccessibilityTrackingObject(type: .buttonShapes),
                    AccessibilityTrackingObject(type: .reduceMotion),
                    AccessibilityTrackingObject(type: .voiceOver),
                    AccessibilityTrackingObject(type: .fontScale)
                ]
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AccessibilityKitView()
        }
    }
}
