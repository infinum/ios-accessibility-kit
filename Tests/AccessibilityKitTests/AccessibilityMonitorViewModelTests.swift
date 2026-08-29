//
//  AccessibilityMonitorViewModelTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

@MainActor
@Suite("AccessibilityMonitorViewModel")
struct AccessibilityMonitorViewModelTests {

    ///
    /// The monitor UI must be a bystander: presenting it must not replace an
    /// observation the app has registered, and dismissing it must not leave
    /// the app deaf.
    ///
    @Test("Shows snapshots without replacing the app's observation")
    func showsSnapshotsWithoutReplacingAppObservation() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let appCounter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in appCounter.increment() }
        await poll(until: { appCounter.count == 1 })

        let viewModel = AccessibilityMonitorViewModel(monitor: monitor)
        await poll(until: { !viewModel.states.isEmpty })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 2 })

        #expect(appCounter.count == 2)
        #expect(viewModel.states.first?.type == .voiceOver)
        withExtendedLifetime(monitor) { }
    }
}
