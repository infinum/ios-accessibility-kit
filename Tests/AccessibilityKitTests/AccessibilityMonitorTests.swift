//
//  AccessibilityMonitorTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

@Suite("AccessibilityMonitor")
struct AccessibilityMonitorTests {

    @Test("Emits the initial snapshot on the main queue")
    func emitsInitialSnapshotOnMainQueue() async {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .initial))

        let isMain: Bool = await withCheckedContinuation { continuation in
            monitor.observeAccessibilityTracking { _ in
                continuation.resume(returning: Thread.isMainThread)
            }
        }

        #expect(isMain)
    }

    @Test("Does not emit again for a change when fetching once")
    func doesNotEmitAgainForInitialFetch() async {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.settle()

        #expect(counter.count == 1)
    }

    @Test("Emits again for every change when observing continuously")
    func emitsForEveryChangeWhenContinuous() async {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.wait(until: { counter.count == 2 })

        #expect(counter.count == 2)
    }

    @Test("Observes the features supplied by the newest configuration")
    func observesTheNewestConfiguration() async {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .continuous))
        monitor.configureAccessibilityTracking(
            with: AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await Self.wait(until: { counter.count == 2 })

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.settle()

        #expect(counter.count == 2)
    }
}

// MARK: - Helpers

private extension AccessibilityMonitorTests {

    static func configuration(fetchType: AccessibilityFetchType) -> AccessibilityTrackingConfiguration {
        return AccessibilityTrackingConfiguration(
            fetchType: fetchType,
            objects: [AccessibilityTrackingObject(type: .voiceOver)]
        )
    }

    ///
    /// Polls until the expectation holds, so a positive assertion never
    /// depends on a fixed delay being long enough.
    ///
    static func wait(until condition: () -> Bool, timeout: TimeInterval = 2) async {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    ///
    /// A fixed wait, used only where the assertion is that nothing *further*
    /// happens — absence cannot be established by polling.
    ///
    static func settle() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
}

/// Only ever touched on the main queue, where the monitor delivers.
private final class EmissionCounter {

    private(set) var count = 0

    func increment() {
        count += 1
    }
}
