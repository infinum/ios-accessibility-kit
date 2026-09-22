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

        var viewModel: AccessibilityMonitorViewModel? = AccessibilityMonitorViewModel(monitor: monitor)
        await poll(until: { !(viewModel?.states.isEmpty ?? true) })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 2 })

        #expect(appCounter.count == 2)
        #expect(viewModel?.states.first?.type == .voiceOver)

        // Dismissing the monitor releases its view model, which must leave
        // the app's own observation exactly as it was.
        weak var released = viewModel
        viewModel = nil

        #expect(released == nil)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 3 })

        #expect(appCounter.count == 3)
        withExtendedLifetime(monitor) { }
    }
}
