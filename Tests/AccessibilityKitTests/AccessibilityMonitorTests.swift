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
///
@Suite("AccessibilityMonitor")
@MainActor
struct AccessibilityMonitorTests {

    @Test("Emits the initial snapshot on the main queue")
    func emitsInitialSnapshotOnMainQueue() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let recorder = MainThreadRecorder()
        monitor.observeAccessibilityTracking { _ in recorder.record(Thread.isMainThread) }
        await poll(until: { recorder.wasMainThread != nil })

        #expect(recorder.wasMainThread == true)
        withExtendedLifetime(monitor) { }
    }

    @Test("Does not emit again for a change when fetching once")
    func doesNotEmitAgainForInitialFetch() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await poll(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await settle()

        #expect(counter.count == 1)
        withExtendedLifetime(monitor) { }
    }

    @Test("Emits again for every change when observing continuously")
    func emitsForEveryChangeWhenContinuous() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await poll(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { counter.count == 2 })

        #expect(counter.count == 2)
        withExtendedLifetime(monitor) { }
    }

    @Test("Observes the features supplied by the newest configuration")
    func observesTheNewestConfiguration() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await poll(until: { counter.count == 1 })

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await poll(until: { counter.count == 2 })

        // Asserted before the next post: polling returns at its timeout
        // without failing, so a boldText change that never arrived would
        // otherwise be covered by the voiceOver post below.
        #expect(counter.count == 2)

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await settle()

        #expect(counter.count == 2)
        withExtendedLifetime(monitor) { }
    }

    @Test("Keeps an existing observation when tracking is reconfigured")
    func keepsObservationAcrossReconfiguration() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await poll(until: { counter.count == 1 })

        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        await settle()

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await poll(until: { counter.count == 2 })

        #expect(counter.count == 2)
        withExtendedLifetime(monitor) { }
    }

    @Test("Delivers nothing when tracking has not been configured")
    func deliversNothingWithoutConfiguration() async {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await settle()

        #expect(counter.count == 0)
        withExtendedLifetime(monitor) { }
    }

    @Test("Replaces the previous observation")
    func replacesThePreviousObservation() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let first = EmissionCounter()
        let second = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in first.increment() }
        await poll(until: { first.count == 1 })

        monitor.observeAccessibilityTracking { _ in second.increment() }
        await poll(until: { second.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { second.count == 2 })

        #expect(first.count == 1)
        #expect(second.count == 2)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Registering twice in one turn leaves both initial deliveries in flight.
    /// Each must land in the completion that was registered when it was
    /// created, not whichever happens to be registered when the hop completes.
    ///
    @Test("Delivers an in-flight snapshot to the completion that observed it")
    func deliversInFlightSnapshotToItsOwnCompletion() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let first = EmissionCounter()
        let second = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in first.increment() }
        monitor.observeAccessibilityTracking { _ in second.increment() }
        await poll(until: { first.count == 1 && second.count == 1 })

        #expect(first.count == 1)
        #expect(second.count == 1)
        withExtendedLifetime(monitor) { }
    }
}

// MARK: - Helpers

private extension AccessibilityMonitorTests {

    static func configuration(fetchType: AccessibilityFetchType) throws -> AccessibilityTrackingConfiguration {
        return try AccessibilityTrackingConfiguration(
            fetchType: fetchType,
            objects: [AccessibilityTrackingObject(type: .voiceOver)]
        )
    }

}

///
/// Records whether the delivery arrived on the main thread.
///
@MainActor
private final class MainThreadRecorder {

    private(set) var wasMainThread: Bool?

    func record(_ value: Bool) {
        wasMainThread = value
    }
}
