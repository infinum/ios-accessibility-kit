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

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        #expect(counter.count == 1)
        #expect(counter.lastDeliveryWasOnMainThread == true)
        withExtendedLifetime(monitor) { }
    }

    @Test("Does not emit again for a change when fetching once")
    func doesNotEmitAgainForInitialFetch() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.wait(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.settle()

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
            await Self.wait(until: { counter.count == 1 })
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
        await Self.wait(until: { counter.count == 1 })

        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        await Self.settle()

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await Self.wait(until: { counter.count == 2 })

        #expect(counter.count == 2)

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.settle()

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
        await Self.wait(until: { counter.count == 1 })

        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        await Self.wait(until: { counter.count >= 2 })
        await Self.settle()

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
        await Self.wait(until: { counter.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        monitor.observeAccessibilityTracking { counter.record($0) }
        await Self.wait(until: { counter.emittedTypes.contains([.boldText]) })

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

        await Self.wait(until: { counter.count == 1 })

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
        await Self.wait(until: { counter.emittedTypes.contains([.boldText]) })

        #expect(counter.emittedTypes == [[.boldText]])
        withExtendedLifetime(monitor) { }
    }

    @Test("Delivers nothing when tracking has not been configured")
    func deliversNothingWithoutConfiguration() async {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in counter.increment() }
        await Self.settle()

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
        await Self.wait(until: { first.count == 1 })

        monitor.observeAccessibilityTracking { _ in second.increment() }
        await Self.wait(until: { second.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await Self.wait(until: { second.count == 2 })

        #expect(first.count == 1)
        #expect(second.count == 2)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// Registering twice in one turn leaves both first snapshots in flight.
    /// The replaced completion must not be called, and the replacement must
    /// receive its own first snapshot once, not the replaced one's as well.
    ///
    /// The settle after the poll is what catches an extra delivery: the
    /// poll returns as soon as the replacement has one.
    ///
    @Test("Delivers the first snapshot once, to the replacement, when observing twice in one turn")
    func deliversFirstSnapshotOnceToReplacement() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let first = EmissionCounter()
        let second = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in first.increment() }
        monitor.observeAccessibilityTracking { _ in second.increment() }
        await Self.wait(until: { second.count == 1 })
        await Self.settle()

        #expect(first.count == 0)
        #expect(second.count == 1)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// There is no way to stop observing other than replacing the
    /// completion, so a replaced completion must not be called again, not
    /// even for a change it was registered for when the change happened.
    ///
    @Test("Does not call a replaced completion for a change already in flight")
    func doesNotCallReplacedCompletionForChangeInFlight() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let first = EmissionCounter()
        let second = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in first.increment() }
        await Self.wait(until: { first.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        monitor.observeAccessibilityTracking { _ in second.increment() }
        await Self.wait(until: { second.count == 1 })
        await Self.settle()

        #expect(first.count == 1)
        #expect(second.count == 1)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// A snapshot nobody can receive is not worth reading: a transform runs
    /// once per snapshot taken, so counting its calls shows whether one was.
    /// A change is handled inside the post, so no wait is needed.
    ///
    @Test("Takes no snapshot for a change while nothing is observing")
    func takesNoSnapshotWithoutObservation() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        let transformCalls = EmissionCounter()
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(
                        type: .voiceOver,
                        transform: { value in
                            transformCalls.increment()
                            return value
                        }
                    )
                ]
            )
        )

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(transformCalls.count == 0)
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
/// Main-actor isolated, like everything else here: the monitor delivers on
/// the main actor and the tests poll from it, so the count needs no lock of
/// its own - the isolation is the guarantee, and the compiler checks it.
///
@MainActor
private final class EmissionCounter {

    private(set) var count = 0
    /// The features each emitted snapshot reported, in delivery order.
    private(set) var emittedTypes = [[AccessibilityType]]()
    private(set) var lastDeliveryWasOnMainThread: Bool?
    /// The identifiers the most recently recorded snapshot reported.
    private(set) var lastIdentifiers = [String]()

    func increment() {
        count += 1
        lastDeliveryWasOnMainThread = Thread.isMainThread
    }

    func record(_ snapshot: AccessibilitySnapshot) {
        emittedTypes.append(snapshot.states.map(\.type))
        lastIdentifiers = snapshot.states.map(\.identifier)
        increment()
    }
}
