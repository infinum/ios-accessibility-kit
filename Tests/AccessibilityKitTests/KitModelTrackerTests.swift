//
//  KitModelTrackerTests.swift
//  AccessibilityKitTests
//

import Combine
import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

@MainActor
@Suite("KitModel with a tracker")
struct KitModelTrackerTests {

    ///
    /// The monitor UI must be a bystander: presenting it must not replace an
    /// observation the app has registered, and dismissing it must not leave
    /// the app deaf.
    ///
    @Test("Shows snapshots without replacing the app's observation")
    func showsSnapshotsWithoutReplacingAppObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let appCounter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in appCounter.increment() }
        queue.run()

        var model: KitModel? = KitModel(tracker: tracker)
        queue.run()

        // Subscribed after the first snapshot has landed, so only the change
        // is counted: the VoiceOver value comes from the system and cannot be
        // flipped here, so the rows alone would look the same either way.
        let displayUpdates = EmissionCounter()
        let subscription = model?.$display.dropFirst().sink { _ in displayUpdates.increment() }

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(appCounter.count == 2)
        #expect(displayUpdates.count == 1)
        #expect(model?.rows.first?.type == .voiceOver)
        subscription?.cancel()

        // Dismissing the Monitor releases its model, which must leave
        // the app's own observation exactly as it was.
        // Declared, then assigned: `weak let` needs Swift 6.2.
        weak var released: KitModel?
        released = model
        model = nil

        #expect(released == nil)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(appCounter.count == 3)
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// Reconfiguring refreshes the Monitor, so the model must take every
    /// snapshot it is handed, not only its first.
    ///
    @Test("Shows the newly configured features after reconfiguring")
    func showsNewlyConfiguredFeatures() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let model = KitModel(tracker: tracker)
        queue.run()

        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        queue.run()

        #expect(model.rows.map(\.type) == [.boldText])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The tracker holds the model weakly, so unless the model
    /// holds the tracker, a tracker nobody else keeps goes away and the
    /// screen silently stops updating.
    ///
    @Test("Keeps its tracker alive for as long as it lives")
    func keepsItsTrackerAlive() {
        weak var released: AccessibilityTracker?
        let model: KitModel

        do {
            let queue = ManualDeliveryQueue()
            let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
            released = tracker
            model = KitModel(tracker: tracker)
        }

        #expect(released != nil)
        withExtendedLifetime(model) { }
    }

    ///
    /// The public `AccessibilityMonitorView` builds its model with no
    /// arguments, so the default must be the tracker the shared kit
    /// configures. The status is read when the model is created, and a
    /// tracker nobody configured would report nothing tracked. That the app's
    /// observation keeps receiving changes while the model is open is
    /// covered above, on a tracker of the test's own.
    ///
    @Test("Shows the shared kit's tracking with its default wiring")
    func showsSharedTrackingByDefault() throws {
        AccessibilityKit.shared.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .voiceOver)]
            )
        )

        let model = KitModel()

        #expect(model.trackingStatus == .live)
    }
}
