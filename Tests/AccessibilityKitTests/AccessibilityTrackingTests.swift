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
    /// produced. The accessibility monitor observes through the same path.
    ///
    /// `.initial` emits exactly once, which keeps the continuation safe.
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

        let snapshot: AccessibilitySnapshot = await withCheckedContinuation { continuation in
            kit.observeAccessibilityTracking { snapshot in
                continuation.resume(returning: snapshot)
            }
        }

        #expect(snapshot.states.first?.value == .flag(true))
        #expect(snapshot.states.first?.identifier == "large_text_enabled")
        withExtendedLifetime(kit) { }
    }
}
