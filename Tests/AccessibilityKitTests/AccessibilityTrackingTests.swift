//
//  AccessibilityTrackingTests.swift
//  AccessibilityKitTests
//

import Testing
@testable import AccessibilityKit

@Suite("Accessibility tracking")
struct AccessibilityTrackingTests {

    ///
    /// Proves a transform reaches the observation path, not just the snapshot
    /// returned directly — the whole point of applying it where states are
    /// produced. The accessibility monitor observes through the same path.
    ///
    /// Uses the shared monitor, so it configures tracking it does not reset.
    /// `.initial` emits exactly once, which keeps the continuation safe.
    ///
    @Test("Applies transforms to observed snapshots")
    func appliesTransformToObservedSnapshot() async {
        let snapshot: AccessibilitySnapshot = await withCheckedContinuation { continuation in
            AccessibilityKit.shared.configureAccessibilityTracking(
                with: AccessibilityTrackingConfiguration(
                    fetchType: .initial,
                    objects: [
                        AccessibilityTrackingObject(
                            type: .fontScale,
                            customIdentifier: "large_text_enabled",
                            transform: { _ in .flag(true) }
                        )
                    ]
                )
            )

            AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
                continuation.resume(returning: snapshot)
            }
        }

        #expect(snapshot.states.first?.value == .flag(true))
        #expect(snapshot.states.first?.identifier == "large_text_enabled")
    }
}
