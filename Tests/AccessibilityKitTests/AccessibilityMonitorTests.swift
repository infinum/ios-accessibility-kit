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

        // Reconfiguring emits no snapshot of its own to the completion.
        #expect(counter.count == 1)

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
        await poll(until: { second.count == 1 })
        await settle()

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
        monitor.observeAccessibilityTracking { _ in first.increment() }
        await poll(until: { first.count == 1 })

        // Posted and replaced in the same turn, so the change's delivery is
        // still scheduled when the second completion takes over.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        let second = EmissionCounter()
        monitor.observeAccessibilityTracking { _ in second.increment() }
        await poll(until: { second.count == 1 })
        await settle()

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

    ///
    /// Two registrations of one observer is what re-presenting the monitor
    /// looks like.
    ///
    @Test("Tells an observer added twice only once")
    func tellsAnObserverAddedTwiceOnlyOnce() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        monitor.addSnapshotObserver(observer)
        await poll(until: { !observer.snapshots.isEmpty })
        await settle()

        #expect(observer.snapshots.count == 1)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { observer.snapshots.count == 2 })

        #expect(observer.snapshots.count == 2)
        withExtendedLifetime(monitor) { }
    }

    @Test("Delivers the current snapshot to a newly added snapshot observer")
    func deliversCurrentSnapshotToANewSnapshotObserver() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)

        // Never inside the registration call, as for the app's completion.
        #expect(observer.snapshots.isEmpty)

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

    ///
    /// Replacing the app's completion drops what was in flight for the old
    /// one, but the monitor UI is not the app's completion: the change it
    /// was registered for when the change happened still reaches it.
    ///
    @Test("Still notifies snapshot observers of a change in flight when the completion is replaced")
    func notifiesSnapshotObserversAcrossReplacedCompletion() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let first = EmissionCounter()
        let observer = SpySnapshotObserver()
        monitor.observeAccessibilityTracking { _ in first.increment() }
        monitor.addSnapshotObserver(observer)
        await poll(until: { first.count == 1 && observer.snapshots.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        monitor.observeAccessibilityTracking { _ in }
        await poll(until: { observer.snapshots.count == 2 })
        await settle()

        #expect(first.count == 1)
        #expect(observer.snapshots.count == 2)
        withExtendedLifetime(monitor) { }
    }

    ///
    /// The change, the reconfiguration and the second change all run in one
    /// main-actor turn, so the stale snapshot, the reconfiguration's refresh
    /// and the second change are all queued before any is delivered. Waiting
    /// for three deliveries bounds the wait: had the stale snapshot been
    /// delivered, it would have been the second.
    ///
    @Test("Drops a snapshot observer's snapshot from a replaced configuration")
    func dropsSnapshotObserverSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await poll(until: { observer.snapshots.count == 1 })

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await poll(until: { observer.snapshots.count >= 3 })

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText], [.boldText]])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// The snapshot observer's counterpart of "Drops a first snapshot taken
    /// under a configuration that has since been replaced": its first
    /// snapshot is scheduled on its own path.
    ///
    @Test("Drops a snapshot observer's first snapshot from a replaced configuration")
    func dropsSnapshotObserverFirstSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        await poll(until: { observer.snapshots.count >= 2 })
        await settle()

        // The reconfiguration's refresh, then the change; never the stale first.
        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.boldText], [.boldText]])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// The monitor UI must not keep showing rows for features that are no
    /// longer tracked, and under `.initial` no change would ever replace
    /// them. The app's completion gets nothing from the reconfiguration.
    ///
    @Test("Refreshes snapshot observers, and only them, when tracking is reconfigured")
    func refreshesSnapshotObserversOnReconfiguration() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        monitor.observeAccessibilityTracking { counter.record($0) }
        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await poll(until: { counter.count == 1 && observer.snapshots.count == 1 })

        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        await poll(until: { observer.snapshots.count >= 2 })
        await settle()

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        #expect(counter.emittedTypes == [[.voiceOver]])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// The refresh goes through the same delivery as everything else: never
    /// inside the reconfiguring call, and dropped if tracking is reconfigured
    /// again before it lands, so two reconfigurations in one turn leave the
    /// observer with one refresh, for the second.
    ///
    @Test("Refreshes snapshot observers asynchronously, once for the last of several reconfigurations")
    func refreshesSnapshotObserversOnceForTheLastReconfiguration() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await poll(until: { observer.snapshots.count == 1 })

        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .reduceMotion)]
            )
        )

        #expect(observer.snapshots.count == 1)

        await poll(until: { observer.snapshots.count >= 2 })
        await settle()

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.reduceMotion]])
        withExtendedLifetime(monitor) { }
    }

    ///
    /// A change is handed to the observers registered when it was scheduled,
    /// so an observer added while it is in flight gets only its own first
    /// snapshot.
    ///
    @Test("Leaves a change already in flight out of an observer added after it")
    func leavesInFlightChangeOutOfALaterObserver() async throws {
        let center = NotificationCenter()
        let monitor = AccessibilityMonitor(notificationCenter: center)
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        let observer = SpySnapshotObserver()
        monitor.addSnapshotObserver(observer)
        await poll(until: { !observer.snapshots.isEmpty })
        await settle()

        #expect(observer.snapshots.count == 1)
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

// MARK: - Recorder

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
