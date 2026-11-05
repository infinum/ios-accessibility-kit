//
//  AccessibilityMonitorViewModelTests.swift
//  AccessibilityKitTests
//

import Combine
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

        // Subscribed after the first snapshot has landed, so only the change
        // is counted: the VoiceOver value comes from the system and cannot be
        // flipped here, so the rows alone would look the same either way.
        let stateUpdates = EmissionCounter()
        let subscription = viewModel?.$states.dropFirst().sink { _ in stateUpdates.increment() }

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 2 && stateUpdates.count == 1 })

        #expect(appCounter.count == 2)
        #expect(stateUpdates.count == 1)
        #expect(viewModel?.states.first?.type == .voiceOver)
        subscription?.cancel()

        // Dismissing the monitor releases its view model, which must leave
        // the app's own observation exactly as it was.
        // Declared, then assigned: `weak let` needs Swift 6.2.
        weak var released: AccessibilityMonitorViewModel?
        released = viewModel
        viewModel = nil

        #expect(released == nil)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 3 })

        #expect(appCounter.count == 3)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Reconfiguring refreshes the monitor, so the view model must take every
    /// snapshot it is handed, not only its first.
    ///
    @Test("Shows the newly configured features after reconfiguring")
    func showsNewlyConfiguredFeatures() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let viewModel = AccessibilityMonitorViewModel(monitor: monitor)
        await poll(until: { viewModel.states.map(\.type) == [.voiceOver] })

        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        await poll(until: { viewModel.states.map(\.type) == [.boldText] })

        #expect(viewModel.states.map(\.type) == [.boldText])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Uses the shared instances, as production does, so the view model's
    /// default wiring is what is under test: had it registered through the
    /// app's single observation slot, the completion below would go quiet.
    ///
    @Test("Leaves the shared observation alone with its default wiring")
    func leavesSharedObservationAlone() async throws {
        let kit = AccessibilityKit.shared
        kit.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let appCounter = EmissionCounter()
        kit.observeAccessibilityTracking { _ in appCounter.increment() }
        await poll(until: { appCounter.count == 1 })

        let viewModel = AccessibilityMonitorViewModel()
        await poll(until: { !viewModel.states.isEmpty })

        #expect(!viewModel.states.isEmpty)

        NotificationCenter.default.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 2 })

        #expect(appCounter.count == 2)
        withExtendedLifetime(viewModel) { }
    }
}
