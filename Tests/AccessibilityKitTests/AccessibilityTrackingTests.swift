//
//  AccessibilityTrackingTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@Suite("Accessibility tracking")
@MainActor
struct AccessibilityTrackingTests {

    ///
    /// Proves a transform reaches the observation path, not just the snapshot
    /// returned directly — the whole point of applying it where states are
    /// produced.
    ///
    @Test("Applies transforms to observed snapshots")
    func appliesTransformToObservedSnapshot() async throws {
        let queue = ManualDeliveryQueue()
        let kit = AccessibilityKit(
            tracker: AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        )

        let configuration = try AccessibilityTrackingConfiguration(
            fetchType: .initial,
            objects: [
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { _ in .flag(true) }
                )
            ]
        )
        kit.configureAccessibilityTracking(with: configuration)

        let recorder = SnapshotRecorder()
        let observation = kit.observeAccessibilityTracking { recorder.record($0) }
        queue.run()

        // `.initial` reports once, through the kit as through the tracker.
        #expect(recorder.count == 1)
        #expect(recorder.snapshot?.states.first?.value == .flag(true))
        #expect(recorder.snapshot?.states.first?.identifier == "large_text_enabled")
        withExtendedLifetime((kit, observation)) { }
    }
}

// MARK: - Recorder

///
/// Holds the last delivered snapshot, and counts deliveries so a repeated
/// one shows.
///
@MainActor
private final class SnapshotRecorder {

    private(set) var snapshot: AccessibilitySnapshot?
    private(set) var count = 0

    func record(_ snapshot: AccessibilitySnapshot) {
        self.snapshot = snapshot
        count += 1
    }
}
