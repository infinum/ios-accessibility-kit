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
        let kit = AccessibilityKit.shared
        let launch = LaunchOptions()

        if !launch.tracksNothing {
            do {
                let configuration = try AccessibilityTrackingConfiguration(
                    fetchType: launch.fetchType,
                    objects: AccessibilityType.allCases.map { AccessibilityTrackingObject(type: $0) }
                )
                kit.configureAccessibilityTracking(with: configuration)
            } catch {
                // Every type is listed once, so a rejected configuration is a
                // mistake in this list rather than a runtime condition.
                assertionFailure("Invalid accessibility tracking configuration: \(error)")
            }
        }

        // The kit is a debugging aid: keep its entry points out of release builds.
        #if DEBUG
        kit.entryPoints = [.floatingButton, .shake]
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProductView()
            }
        }
    }
}

///
/// Launch arguments for trying the kit's states, set in the Example scheme:
///
/// - `-kitFetchType initial` tracks a one-time snapshot instead of live changes.
/// - `-kitTrackNothing` leaves tracking unconfigured.
///
private struct LaunchOptions {

    let fetchType: AccessibilityFetchType
    let tracksNothing: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments, defaults: UserDefaults = .standard) {
        fetchType = defaults.string(forKey: "kitFetchType") == "initial" ? .initial : .continuous
        tracksNothing = arguments.contains("-kitTrackNothing")
    }
}
