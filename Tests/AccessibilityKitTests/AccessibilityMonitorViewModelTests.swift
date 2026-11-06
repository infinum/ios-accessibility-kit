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
        let tracker = AccessibilityTracker(notificationCenter: center)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let appCounter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in appCounter.increment() }
        await poll(until: { appCounter.count == 1 })

        var viewModel: AccessibilityMonitorViewModel? = AccessibilityMonitorViewModel(tracker: tracker)
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
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// Reconfiguring refreshes the monitor, so the view model must take every
    /// snapshot it is handed, not only its first.
    ///
    @Test("Shows the newly configured features after reconfiguring")
    func showsNewlyConfiguredFeatures() async throws {
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter())
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let viewModel = AccessibilityMonitorViewModel(tracker: tracker)
        await poll(until: { viewModel.states.map(\.type) == [.voiceOver] })

        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        await poll(until: { viewModel.states.map(\.type) == [.boldText] })

        #expect(viewModel.states.map(\.type) == [.boldText])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The tracker holds the view model weakly, so unless the view model
    /// holds the tracker, a tracker nobody else keeps goes away and the
    /// screen silently stops updating.
    ///
    @Test("Keeps its tracker alive for as long as it lives")
    func keepsItsTrackerAlive() {
        weak var released: AccessibilityTracker?
        let viewModel: AccessibilityMonitorViewModel

        do {
            let tracker = AccessibilityTracker(notificationCenter: NotificationCenter())
            released = tracker
            viewModel = AccessibilityMonitorViewModel(tracker: tracker)
        }

        #expect(released != nil)
        withExtendedLifetime(viewModel) { }
    }

    ///
    /// Uses the shared instances, as production does, so the view model's
    /// default wiring is what is under test: the app's completion must keep
    /// receiving changes while the kit's UI is open.
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
        let observation = kit.observeAccessibilityTracking { _ in appCounter.increment() }
        await poll(until: { appCounter.count == 1 })

        let viewModel = AccessibilityMonitorViewModel()
        await poll(until: { !viewModel.states.isEmpty })

        #expect(!viewModel.states.isEmpty)

        NotificationCenter.default.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { appCounter.count == 2 })

        #expect(appCounter.count == 2)
        withExtendedLifetime((viewModel, observation)) { }
    }
}
