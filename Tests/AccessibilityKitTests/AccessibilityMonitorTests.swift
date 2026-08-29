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

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { counter.count == 3 })

        #expect(counter.count == 3)
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

    ///
    /// Waits for the initial snapshot first, so the monitor has been
    /// configured, observed and has delivered before it is let go: its
    /// release then shows no subject or pending delivery holds it.
    ///
    @Test("Releases a configured monitor once nothing else holds it")
    func releasesConfiguredMonitor() async throws {
        let counter = EmissionCounter()
        weak var released: AccessibilityMonitor?

        do {
            let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
            monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
            monitor.observeAccessibilityTracking { _ in counter.increment() }
            released = monitor
            await poll(until: { counter.count == 1 })
        }

        #expect(counter.count == 1)
        #expect(released == nil)
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

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await settle()

        #expect(counter.count == 2)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// One subject runs per type, whatever the number of objects tracking
    /// it, so a change to a feature tracked twice produces one snapshot
    /// carrying both entries rather than one snapshot per object.
    ///
    @Test("Emits once per change for a feature tracked under two identifiers")
    func emitsOnceForFeatureTrackedTwice() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .fontScale),
                    AccessibilityTrackingObject(
                        type: .fontScale,
                        customIdentifier: "large_text_enabled",
                        transform: { _ in .flag(true) }
                    )
                ]
            )
        )

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { counter.record($0) }
        await poll(until: { counter.count == 1 })

        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        await poll(until: { counter.count >= 2 })
        await settle()

        #expect(counter.count == 2)
        #expect(Set(counter.lastIdentifiers) == ["font_scale", "large_text_enabled"])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Runs on the main actor so the change, the reconfiguration and the
    /// second observation all happen before the main queue gets a chance to
    /// deliver the snapshot the change queued.
    ///
    /// Observing again queues the new configuration's initial snapshot
    /// behind the stale one on the main queue, so its arrival bounds the
    /// wait without a fixed delay: had the stale snapshot been delivered, it
    /// would have arrived first.
    ///
    @Test("Drops a snapshot taken under a configuration that has since been replaced")
    func dropsSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { counter.record($0) }
        await poll(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        monitor.observeAccessibilityTracking { counter.record($0) }
        await poll(until: { counter.emittedTypes.contains([.boldText]) })

        #expect(counter.emittedTypes == [[.voiceOver], [.boldText]])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// The completion must never run inside the caller's own call to
    /// observe, so nothing has been delivered by the time it returns.
    ///
    @Test("Delivers the first snapshot after observing returns, never inside it")
    func deliversFirstSnapshotAfterObservingReturns() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { counter.record($0) }

        #expect(counter.count == 0)

        await poll(until: { counter.count == 1 })

        #expect(counter.count == 1)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Observing and reconfiguring in one turn leaves the first snapshot in
    /// flight under the replaced configuration. A change posted after the
    /// reconfiguration is delivered behind it, so its arrival bounds the
    /// wait: had the stale first snapshot been delivered, it would have
    /// arrived first.
    ///
    @Test("Drops a first snapshot taken under a configuration that has since been replaced")
    func dropsFirstSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { counter.record($0) }
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await poll(until: { counter.emittedTypes.contains([.boldText]) })

        #expect(counter.emittedTypes == [[.boldText]])
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

    @Test("Delivers the current snapshot to a newly added snapshot observer")
    func deliversCurrentSnapshotToANewSnapshotObserver() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await poll(until: { !observer.snapshots.isEmpty })

        #expect(observer.snapshots.count == 1)
        #expect(observer.snapshots.first?.states.first?.type == .voiceOver)
        withExtendedLifetime(monitor) { }
    }

    @Test("Notifies snapshot observers on every change")
    func notifiesSnapshotObserversOnEveryChange() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await poll(until: { observer.snapshots.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { observer.snapshots.count == 2 })

        #expect(observer.snapshots.count == 2)
        withExtendedLifetime(monitor) { }
    }

    @Test("Delivers nothing to a snapshot observer when tracking is unconfigured")
    func deliversNothingToASnapshotObserverWithoutConfiguration() async {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await settle()

        #expect(observer.snapshots.isEmpty)
        withExtendedLifetime(monitor) { }
    }

    @Test("Does not retain its snapshot observers")
    func doesNotRetainSnapshotObservers() {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        weak var released: SpySnapshotObserver?

        do {
            let observer = SpySnapshotObserver()
            released = observer
            monitor.addSnapshotObserver(observer)
        }

        #expect(released == nil)
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

// MARK: - Spy

///
/// Records every snapshot delivered to it, on the main queue.
///
@MainActor
private final class SpySnapshotObserver: AccessibilitySnapshotObserver {

    private(set) var snapshots = [AccessibilitySnapshot]()

    func accessibilitySnapshotDidChange(_ snapshot: AccessibilitySnapshot) {
        snapshots.append(snapshot)
    }
}
