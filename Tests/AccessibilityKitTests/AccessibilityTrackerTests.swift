//
//  AccessibilityTrackerTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

///
/// Subjects hold their observers weakly, so a tracker is kept alive only by
/// whoever owns it — `AccessibilityKit.shared` in production. Each test must
/// therefore extend its tracker's lifetime past the last assertion, or ARC
/// releases it after its final use and the notification reaches nobody.
/// The release test is the exception: letting go of it is what it checks.
///
@Suite("AccessibilityTracker")
@MainActor
struct AccessibilityTrackerTests {

    ///
    /// The one test on the real main queue, which the tracker delivers on
    /// outside tests; every other test runs a delivery queue by hand.
    ///
    @Test("Delivers on the main queue by default")
    func deliversOnTheMainQueueByDefault() async throws {
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter())
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let recorder = MainThreadRecorder()
        let observation = tracker.observeAccessibilityTracking { _ in recorder.record(Thread.isMainThread) }
        await poll(until: { recorder.wasMainThread != nil })

        #expect(recorder.wasMainThread == true)
        withExtendedLifetime((tracker, observation)) { }
    }

    @Test("Does not emit again for a change when fetching once")
    func doesNotEmitAgainForInitialFetch() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 1)
        withExtendedLifetime((tracker, observation)) { }
    }

    @Test("Emits again for every change when observing continuously")
    func emitsForEveryChangeWhenContinuous() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 2)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 3)
        withExtendedLifetime((tracker, observation)) { }
    }

    @Test("Observes the features supplied by the newest configuration")
    func observesTheNewestConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        // Asserted before the next post, so a boldText change that never
        // arrived cannot be covered by the voiceOver post below.
        #expect(counter.count == 2)

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 2)
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// Delivers the initial snapshot first, so the tracker has been
    /// configured, observed and has delivered before it is let go: its
    /// release then shows no subject or pending delivery holds it.
    ///
    @Test("Releases a configured tracker once nothing else holds it")
    func releasesConfiguredTracker() async throws {
        let counter = EmissionCounter()
        weak var released: AccessibilityTracker?

        do {
            let queue = ManualDeliveryQueue()
            let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
            tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
            let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
            released = tracker
            queue.run()
            withExtendedLifetime(observation) { }
        }

        #expect(counter.count == 1)
        #expect(released == nil)
    }

    @Test("Keeps an existing observation when tracking is reconfigured")
    func keepsObservationAcrossReconfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        queue.run()

        // Reconfiguring emits no snapshot of its own to the completion.
        #expect(counter.count == 1)

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 2)

        // The replaced configuration's feature must no longer be observed.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 2)
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// One subject runs per type, whatever the number of objects tracking
    /// it, so a change to a feature tracked twice produces one snapshot
    /// carrying both entries rather than one snapshot per object.
    ///
    @Test("Emits once per change for a feature tracked under two identifiers")
    func emitsOnceForFeatureTrackedTwice() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(
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
        let observation = tracker.observeAccessibilityTracking { counter.record($0) }
        queue.run()

        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 2)
        #expect(Set(counter.lastIdentifiers) == ["font_scale", "large_text_enabled"])
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The change, the reconfiguration and the second observation all happen
    /// before the queue runs, so the snapshot the change queued is still
    /// pending when tracking is replaced. Had it been delivered, it would
    /// have arrived ahead of the second observation's first snapshot.
    ///
    @Test("Drops a snapshot taken under a configuration that has since been replaced")
    func dropsSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { counter.record($0) }
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        let observation2 = tracker.observeAccessibilityTracking { counter.record($0) }
        queue.run()

        #expect(counter.emittedTypes == [[.voiceOver], [.boldText]])
        withExtendedLifetime((tracker, observation, observation2)) { }
    }

    ///
    /// The debug warning for an observation that was never stored fires when
    /// one ends in the turn it was created in. Still alive when the queue
    /// next runs, it counts as kept.
    ///
    @Test("Counts an observation as kept once it outlives the turn it was created in")
    func countsAnObservationAsKeptAfterItsFirstTurn() throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observation = tracker.observeAccessibilityTracking { _ in }

        #expect(observation.state.wasKept == false)

        queue.run()

        #expect(observation.state.wasKept == true)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The completion must never run inside the caller's own call to
    /// observe, so nothing has been delivered by the time it returns.
    ///
    @Test("Delivers the first snapshot after observing returns, never inside it")
    func deliversFirstSnapshotAfterObservingReturns() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { counter.record($0) }

        #expect(counter.count == 0)

        queue.run()

        #expect(counter.count == 1)
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// Observing and reconfiguring before the queue runs leaves the first
    /// snapshot pending under the replaced configuration. Had it been
    /// delivered, it would have arrived ahead of the change posted after the
    /// reconfiguration.
    ///
    @Test("Drops a first snapshot taken under a configuration that has since been replaced")
    func dropsFirstSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { counter.record($0) }
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.emittedTypes == [[.boldText]])
        withExtendedLifetime((tracker, observation)) { }
    }

    @Test("Delivers nothing when tracking has not been configured")
    func deliversNothingWithoutConfiguration() async {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        #expect(counter.count == 0)
        withExtendedLifetime((tracker, observation)) { }
    }

    @Test("Delivers every change to every observation")
    func deliversToEveryObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let first = EmissionCounter()
        let second = EmissionCounter()
        let firstObservation = tracker.observeAccessibilityTracking { _ in first.increment() }
        queue.run()

        let secondObservation = tracker.observeAccessibilityTracking { _ in second.increment() }
        queue.run()

        // Each observation gets its own first snapshot, and only its own.
        #expect(first.count == 1)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(first.count == 2)
        #expect(second.count == 2)
        withExtendedLifetime((tracker, firstObservation, secondObservation)) { }
    }

    ///
    /// Registering twice in one turn leaves both first snapshots in flight.
    /// Each must reach its own observation once, and only that one.
    ///
    @Test("Delivers each observation its own first snapshot once when observing twice in one turn")
    func deliversEachFirstSnapshotOnce() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let first = EmissionCounter()
        let second = EmissionCounter()
        let firstObservation = tracker.observeAccessibilityTracking { _ in first.increment() }
        let secondObservation = tracker.observeAccessibilityTracking { _ in second.increment() }
        queue.run()

        #expect(first.count == 1)
        #expect(second.count == 1)
        withExtendedLifetime((tracker, firstObservation, secondObservation)) { }
    }

    @Test("Stops calling an observation once it is cancelled")
    func stopsCallingACancelledObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let cancelled = EmissionCounter()
        let kept = EmissionCounter()
        let cancelledObservation = tracker.observeAccessibilityTracking { _ in cancelled.increment() }
        let keptObservation = tracker.observeAccessibilityTracking { _ in kept.increment() }
        queue.run()

        cancelledObservation.cancel()
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(cancelled.count == 1)
        #expect(kept.count == 2)
        withExtendedLifetime((tracker, cancelledObservation, keptObservation)) { }
    }

    ///
    /// Releasing the observation is how most callers will end it, so it
    /// must end the observation just as cancelling does.
    ///
    @Test("Stops calling an observation once it is released")
    func stopsCallingAReleasedObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        var observation: AccessibilityObservation? = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        withExtendedLifetime(observation) { }
        observation = nil
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Ending an observation releases its completion, which may hold the
    /// last reference to another observation. That one ends in turn, from
    /// inside the first one's removal, and must not trip exclusivity.
    ///
    @Test("Ends an observation whose completion holds another observation")
    func endsNestedObservations() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let innerCalls = EmissionCounter()
        let outerCalls = EmissionCounter()
        let keptCalls = EmissionCounter()
        // Declared, then assigned: `weak let` needs Swift 6.2.
        weak var releasedInner: ObservationHolder?
        var outer: AccessibilityObservation?
        do {
            // Reachable only through the outer completion from here on.
            let inner = ObservationHolder()
            inner.observation = tracker.observeAccessibilityTracking { _ in innerCalls.increment() }
            releasedInner = inner
            outer = tracker.observeAccessibilityTracking { _ in
                withExtendedLifetime(inner) { }
                outerCalls.increment()
            }
        }
        let kept = tracker.observeAccessibilityTracking { _ in keptCalls.increment() }
        queue.run()

        // Releasing the outer observation releases the holder, and with it
        // the inner observation, from inside the outer one's removal.
        withExtendedLifetime(outer) { }
        outer = nil

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(releasedInner == nil)
        #expect(innerCalls.count == 1)
        #expect(outerCalls.count == 1)
        #expect(keptCalls.count == 2)
        withExtendedLifetime((tracker, kept)) { }
    }

    ///
    /// An ended observation must not be called again, not even for a change
    /// it was registered for when the change happened.
    ///
    @Test("Does not call a cancelled observation for a change already in flight")
    func doesNotCallCancelledObservationForChangeInFlight() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        // Posted and cancelled before the queue runs, so the change's
        // delivery is still pending when the observation ends.
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        observation.cancel()
        queue.run()

        #expect(counter.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A snapshot nobody can receive is not worth reading: a transform runs
    /// once per snapshot taken, so counting its calls shows whether one was.
    /// A change is handled inside the post, so the queue need not run.
    ///
    @Test("Takes no snapshot for a change while nothing is observing")
    func takesNoSnapshotWithoutObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        let transformCalls = EmissionCounter()
        tracker.configureAccessibilityTracking(with: try Self.configuration(countingTransformsIn: transformCalls))

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(transformCalls.count == 0)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A released observer can leave a dead entry in the list. A dead entry
    /// is nobody, so it must not be enough for a change to take a snapshot.
    ///
    @Test("Takes no snapshot for a change when the only observer has been released")
    func takesNoSnapshotForReleasedObserver() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        let transformCalls = EmissionCounter()
        tracker.configureAccessibilityTracking(with: try Self.configuration(countingTransformsIn: transformCalls))

        do {
            let observer = SpySnapshotObserver()
            tracker.addSnapshotObserver(observer)
        }

        // The observer's own first snapshot, taken when it registered.
        #expect(transformCalls.count == 1)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(transformCalls.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The session history holds the system's own values, read by the
    /// subjects anyway, so it is complete when the kit opens later without
    /// running any of the app's transforms.
    ///
    @Test("Records the system's value on every change, with nothing observing")
    func recordsChangesWithoutObservation() async throws {
        let center = NotificationCenter()
        let system = SystemValues()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: system.read, launchDate: Date(), deliveryQueue: queue)
        let transformCalls = EmissionCounter()
        tracker.configureAccessibilityTracking(with: try Self.configuration(countingTransformsIn: transformCalls))

        system.values[.voiceOver] = .flag(true)
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(tracker.history(for: .voiceOver).map(\.value) == [.flag(false), .flag(true)])
        #expect(tracker.history(for: .voiceOver).map(\.kind) == [.launch, .change])
        #expect(transformCalls.count == 0)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A first configuration long after the process started reads as "when
    /// tracking started", unless the system prewarmed the process: then the
    /// process started long before the launch, and the configuration is the
    /// launch.
    ///
    @Test("Records the first values at launch only when the process was prewarmed or just started", arguments: [false, true])
    func recordsFirstValuesAtLaunchWhenPrewarmed(isPrewarmed: Bool) throws {
        let tracker = AccessibilityTracker(
            notificationCenter: NotificationCenter(),
            readState: SystemValues().read,
            launchDate: Date(timeIntervalSinceNow: -60),
            isPrewarmed: isPrewarmed,
            deliveryQueue: ManualDeliveryQueue()
        )
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        #expect(tracker.history(for: .voiceOver).map(\.kind) == [isPrewarmed ? .launch : .start])
    }

    ///
    /// A notification can arrive without the value having changed — this
    /// suite posts them freely — and must not read as a change.
    ///
    @Test("Records nothing for a notification that leaves the value as it was")
    func recordsNothingForAnUnchangedValue() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: SystemValues().read, launchDate: Date(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(tracker.history(for: .voiceOver).map(\.kind) == [.launch])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// An app may reconfigure on every return to the foreground. The same
    /// features must keep what they recorded, Changed marks included.
    ///
    @Test("Keeps the session history when tracking is reconfigured with the same features")
    func keepsHistoryOnReconfiguration() async throws {
        let center = NotificationCenter()
        let system = SystemValues()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: system.read, launchDate: Date(), deliveryQueue: queue)
        let configuration = try Self.configuration(fetchType: .continuous)
        tracker.configureAccessibilityTracking(with: configuration)
        system.values[.voiceOver] = .flag(true)
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        tracker.configureAccessibilityTracking(with: configuration)

        #expect(tracker.history(for: .voiceOver).map(\.kind) == [.launch, .change])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Transforms run while a snapshot is taken, and may reconfigure tracking
    /// themselves. The snapshot they were part of was then taken under the
    /// replaced configuration, so it must be dropped rather than land after
    /// the refresh and bring the old rows back.
    ///
    @Test("Drops a change whose own transform reconfigures tracking")
    func dropsChangeWhoseTransformReconfigures() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        let boldText = try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [AccessibilityTrackingObject(type: .boldText)]
        )
        let transformCalls = EmissionCounter()
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(
                        type: .voiceOver,
                        // The first call takes the observer's first snapshot,
                        // the second the change's.
                        transform: { [weak tracker] value in
                            transformCalls.increment()
                            if transformCalls.count == 2 {
                                tracker?.configureAccessibilityTracking(with: boldText)
                            }
                            return value
                        }
                    )
                ]
            )
        )

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(transformCalls.count == 2)
        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Registering an observer that is already registered must not make it
    /// a second recipient of every delivery.
    ///
    @Test("Tells an observer added twice only once")
    func tellsAnObserverAddedTwiceOnlyOnce() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        tracker.addSnapshotObserver(observer)
        queue.run()

        #expect(observer.snapshots.count == 1)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(observer.snapshots.count == 2)
        withExtendedLifetime(tracker) { }
    }

    @Test("Delivers the current snapshot to a newly added snapshot observer")
    func deliversCurrentSnapshotToANewSnapshotObserver() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)

        // Never inside the registration call, as for the app's completion.
        #expect(observer.snapshots.isEmpty)

        queue.run()

        #expect(observer.snapshots.count == 1)
        #expect(observer.snapshots.first?.states.first?.type == .voiceOver)
        withExtendedLifetime(tracker) { }
    }

    @Test("Notifies snapshot observers on every change")
    func notifiesSnapshotObserversOnEveryChange() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(observer.snapshots.count == 2)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Cancelling an observation drops what was in flight for it, but the
    /// kit's UI is not an observation: the change it was registered for
    /// when the change happened still reaches it.
    ///
    @Test("Still notifies snapshot observers of a change in flight when an observation is cancelled")
    func notifiesSnapshotObserversAcrossCancelledObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let first = EmissionCounter()
        let observer = SpySnapshotObserver()
        let observation = tracker.observeAccessibilityTracking { _ in first.increment() }
        tracker.addSnapshotObserver(observer)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        observation.cancel()
        queue.run()

        #expect(first.count == 1)
        #expect(observer.snapshots.count == 2)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A delivery reaches the completion first and the observers after it,
    /// in one turn. A completion that reconfigures tracking makes the
    /// snapshot stale for everyone after it, so the observers must get only
    /// the refresh for the new configuration, never the stale snapshot.
    ///
    @Test("Drops a change for snapshot observers when the completion reconfigures tracking")
    func dropsChangeForObserversWhenCompletionReconfigures() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)

        let boldText = try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [AccessibilityTrackingObject(type: .boldText)]
        )
        let calls = EmissionCounter()
        // Reconfigures when handed the change, not its first snapshot, so the
        // reconfiguration lands between the completion and the observers.
        let observation = tracker.observeAccessibilityTracking { [weak tracker] _ in
            calls.increment()
            guard calls.count == 2 else { return }
            tracker?.configureAccessibilityTracking(with: boldText)
        }
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(calls.count == 2)
        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The change, the reconfiguration and the second change all happen
    /// before the queue runs, so the stale snapshot, the reconfiguration's
    /// refresh and the second change are all pending before any is
    /// delivered. Had the stale snapshot been delivered, it would have been
    /// the second.
    ///
    @Test("Drops a snapshot observer's snapshot from a replaced configuration")
    func dropsSnapshotObserverSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText], [.boldText]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The snapshot observer's counterpart of "Drops a first snapshot taken
    /// under a configuration that has since been replaced": its first
    /// snapshot is scheduled on its own path.
    ///
    @Test("Drops a snapshot observer's first snapshot from a replaced configuration")
    func dropsSnapshotObserverFirstSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        // The reconfiguration's refresh, then the change; never the stale first.
        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.boldText], [.boldText]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The monitor UI must not keep showing rows for features that are no
    /// longer tracked, and under `.initial` no change would ever replace
    /// them. The app's completion gets nothing from the reconfiguration.
    ///
    @Test("Refreshes snapshot observers, and only them, when tracking is reconfigured")
    func refreshesSnapshotObserversOnReconfiguration() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { counter.record($0) }
        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        queue.run()

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        #expect(counter.emittedTypes == [[.voiceOver]])
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The refresh goes through the same delivery as everything else: never
    /// inside the reconfiguring call, and dropped if tracking is reconfigured
    /// again before it lands, so two reconfigurations in one turn leave the
    /// observer with one refresh, for the second.
    ///
    @Test("Refreshes snapshot observers asynchronously, once for the last of several reconfigurations")
    func refreshesSnapshotObserversOnceForTheLastReconfiguration() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .reduceMotion)]
            )
        )

        #expect(observer.snapshots.count == 1)

        queue.run()

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.reduceMotion]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A change is handed to the observers registered when it was scheduled,
    /// so an observer added while it is in flight gets only its own first
    /// snapshot. An observer registered beforehand makes sure the change is
    /// scheduled at all: with nobody to receive it, none would be.
    ///
    @Test("Leaves a change already in flight out of an observer added after it")
    func leavesInFlightChangeOutOfALaterObserver() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let earlier = SpySnapshotObserver()
        tracker.addSnapshotObserver(earlier)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        let later = SpySnapshotObserver()
        tracker.addSnapshotObserver(later)
        queue.run()

        #expect(earlier.snapshots.count == 2)
        #expect(later.snapshots.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A monitor opened before tracking is configured stays empty, and is
    /// filled in by the refresh once tracking is configured.
    ///
    @Test("Fills in a snapshot observer added before tracking is configured")
    func fillsInASnapshotObserverAddedBeforeConfiguration() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        #expect(observer.snapshots.isEmpty)

        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))
        queue.run()

        #expect(observer.snapshots.map { $0.states.map(\.type) } == [[.voiceOver]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The monitor UI is held to the fetch type like the completion is:
    /// under `.initial` it keeps the values from when it was presented.
    ///
    @Test("Does not notify a snapshot observer of a change when fetching once")
    func doesNotNotifySnapshotObserverForInitialFetch() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let observer = SpySnapshotObserver()
        tracker.addSnapshotObserver(observer)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(observer.snapshots.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Configured, so the observer's first snapshot is still in flight when
    /// it is let go: the pending delivery must not hold it either.
    ///
    @Test("Does not retain its snapshot observers")
    func doesNotRetainSnapshotObservers() throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
        weak var released: SpySnapshotObserver?

        do {
            let observer = SpySnapshotObserver()
            released = observer
            tracker.addSnapshotObserver(observer)
        }

        #expect(released == nil)
        withExtendedLifetime(tracker) { }
    }
}

// MARK: - Helpers

private extension AccessibilityTrackerTests {

    static func configuration(fetchType: AccessibilityFetchType) throws -> AccessibilityTrackingConfiguration {
        return try AccessibilityTrackingConfiguration(
            fetchType: fetchType,
            objects: [AccessibilityTrackingObject(type: .voiceOver)]
        )
    }

    ///
    /// A continuous VoiceOver configuration whose transform counts its calls.
    /// It runs once per snapshot taken, so the count shows how many were.
    ///
    static func configuration(countingTransformsIn calls: EmissionCounter) throws -> AccessibilityTrackingConfiguration {
        return try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [
                AccessibilityTrackingObject(
                    type: .voiceOver,
                    transform: { value in
                        calls.increment()
                        return value
                    }
                )
            ]
        )
    }
}

// MARK: - Observation holder

///
/// Owns an observation, so releasing the holder releases the observation.
///
@MainActor
private final class ObservationHolder {

    var observation: AccessibilityObservation?
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
/// Records every snapshot delivered to it.
///
@MainActor
private final class SpySnapshotObserver: AccessibilitySnapshotObserver {

    private(set) var snapshots = [AccessibilitySnapshot]()

    func accessibilitySnapshotDidChange(_ snapshot: AccessibilitySnapshot, reason: SnapshotDeliveryReason) {
        snapshots.append(snapshot)
    }
}
