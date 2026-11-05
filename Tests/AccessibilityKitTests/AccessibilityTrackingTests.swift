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
        let kit = AccessibilityKit(
            monitor: AccessibilityMonitor(notificationCenter: NotificationCenter())
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
        kit.observeAccessibilityTracking { recorder.record($0) }
        await poll(until: { recorder.snapshot != nil })
        await settle()

        // `.initial` reports once, through the kit as through the monitor.
        #expect(recorder.count == 1)
        #expect(recorder.snapshot?.states.first?.value == .flag(true))
        #expect(recorder.snapshot?.states.first?.identifier == "large_text_enabled")
        withExtendedLifetime(kit) { }
    }
}

// MARK: - Recorder

///
/// Holds the last delivered snapshot so the test can poll for it, and counts
/// deliveries so a repeated one shows.
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
