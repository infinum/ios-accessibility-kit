//
//  AccessibilityMonitorTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

///
/// Subjects hold their observers weakly, so a monitor is kept alive only by
/// whoever owns it — `AccessibilityKit.shared` in production. Each test must
/// therefore extend its monitor's lifetime past the last assertion, or ARC
/// releases it after its final use and the notification reaches nobody.
/// The release test is the exception: letting go of it is what it checks.
///
@Suite("AccessibilityMonitor")
struct AccessibilityMonitorTests {

    @Test("Emits the initial snapshot on the main queue")
    func emitsInitialSnapshotOnMainQueue() async {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        #expect(counter.count == 1)
        #expect(counter.lastDeliveryWasOnMainThread == true)
        withExtendedLifetime(monitor) { }
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
        withExtendedLifetime(monitor) { }
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

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.wait(until: { counter.count == 3 })

        #expect(counter.count == 3)
        withExtendedLifetime(monitor) { }
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

        // Asserted before the next post: polling returns at its timeout
        // without failing, so a boldText change that never arrived would
        // otherwise be covered by the voiceOver post below.
        #expect(counter.count == 2)

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.settle()

        #expect(counter.count == 2)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Waits for the initial snapshot first: it is delivered after the
    /// subjects are configured, so by then a subject holding the monitor
    /// strongly would already keep it alive.
    ///
    @Test("Releases a configured monitor once nothing else holds it")
    func releasesConfiguredMonitor() async {
        let counter = EmissionCounter()
        weak var released: AccessibilityMonitor?

        do {
            let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
            monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .continuous))
            monitor.observeAccessibilityTracking { _ in counter.increment() }
            released = monitor
            await Self.wait(until: { counter.count == 1 })
        }

        #expect(counter.count == 1)
        #expect(released == nil)
    }

    @Test("Keeps an existing observation when tracking is reconfigured")
    func keepsObservationAcrossReconfiguration() async {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        monitor.configureAccessibilityTracking(
            with: AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        await Self.settle()

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await Self.wait(until: { counter.count == 2 })

        #expect(counter.count == 2)
        withExtendedLifetime(monitor) { }
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
    /// depends on a fixed delay being long enough. The timeout is generous
    /// because a cold simulator has been seen to delay a main-queue
    /// delivery past two seconds.
    ///
    static func wait(until condition: () -> Bool, timeout: TimeInterval = 5) async {
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

///
/// Written on the main queue, where the monitor delivers, and read from the
/// test task that polls it, so the count and the delivery thread are guarded.
///
private final class EmissionCounter {

    private let lock = NSLock()
    private var value = 0
    private var lastWasOnMainThread: Bool?

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    var lastDeliveryWasOnMainThread: Bool? {
        lock.lock()
        defer { lock.unlock() }
        return lastWasOnMainThread
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        lastWasOnMainThread = Thread.isMainThread
    }
}
