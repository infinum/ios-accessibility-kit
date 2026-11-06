//
//  AccessibilityTrackerTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

///
/// A tracker's notification registrations hold it weakly, so it is kept
/// alive only by whoever owns it — `AccessibilityKit.shared` in production.
/// Each test must therefore extend its tracker's lifetime past the last
/// assertion, or ARC releases it after its final use and the notification
/// reaches nobody.
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
    /// release then shows no registration or pending delivery holds it.
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

    ///
    /// The reconfiguration tests post a feature that is no longer tracked.
    /// This one posts a feature that never was.
    ///
    @Test("Ignores notifications for features it does not track")
    func ignoresUntrackedFeatures() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(counter.count == 1)
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The notification centre is not the library's, so anything in the
    /// process can post these names from a background thread. That must
    /// reach the tracker as a change rather than trap the process on the
    /// main-actor assumption.
    ///
    @Test("Handles a change posted from a background thread")
    func handlesChangePostedOffTheMainThread() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { _ in counter.increment() }
        queue.run()

        DispatchQueue.global().async {
            center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        }

        // The change reaches the main actor on a later turn, and its
        // delivery is queued from there.
        await poll(until: {
            queue.run()
            return counter.count == 2
        })

        #expect(counter.count == 2)
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The centre is spied on rather than only posted to: Foundation drops
    /// its own reference to an observer once it is freed, so a tracker that
    /// never unregistered would stop hearing changes anyway, and the test
    /// would pass while the contract was broken.
    ///
    @Test("Unregisters from the notification centre when released")
    func unregistersWhenReleased() throws {
        let center = SpyNotificationCenter()

        do {
            let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: ManualDeliveryQueue())
            tracker.configureAccessibilityTracking(
                with: try AccessibilityTrackingConfiguration(
                    fetchType: .continuous,
                    objects: [AccessibilityTrackingObject(type: .voiceOver), AccessibilityTrackingObject(type: .boldText)]
                )
            )
            #expect(center.removedObservers.isEmpty)
        }

        // One registration per tracked feature, each removed, and nothing else.
        #expect(center.addedObservers.count == 2)
        #expect(center.removedObservers.count == 2)
        #expect(Set(center.removedObservers) == Set(center.addedObservers))
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
    /// The tracker registers once per type, whatever the number of objects
    /// tracking it, so a change to a feature tracked twice produces one
    /// snapshot carrying both entries rather than one snapshot per object.
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
    /// A released listener can leave a dead entry in the list. A dead entry
    /// is nobody, so it must not be enough for a change to take a snapshot.
    ///
    @Test("Takes no snapshot for a change when the only listener has been released")
    func takesNoSnapshotForReleasedListener() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        let transformCalls = EmissionCounter()
        tracker.configureAccessibilityTracking(with: try Self.configuration(countingTransformsIn: transformCalls))

        do {
            let listener = SpyListener()
            tracker.addListener(listener)
        }

        // The listener's own first update, taken when it registered: the
        // snapshot and its history both ran the transform.
        let callsAtRegistration = transformCalls.count
        #expect(callsAtRegistration > 0)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(transformCalls.count == callsAtRegistration)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The session history holds the system's own values, read on every
    /// notification anyway, so it is complete when the kit opens later
    /// without running any of the app's transforms.
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

        #expect(transformCalls.count == 0)

        // The kit opens later, and is told everything recorded.
        let history = Self.history(toldBy: tracker, queue: queue)
        #expect(history.map(\.value) == [.flag(false), .flag(true)])
        #expect(history.map(\.kind) == [.launch, .change])
    }

    ///
    /// A first configuration long after the process started reads as "when
    /// tracking started", unless the system prewarmed the process: then the
    /// process started long before the launch, and the configuration is the
    /// launch.
    ///
    @Test("Records the first values at launch only when the process was prewarmed or just started", arguments: [false, true])
    func recordsFirstValuesAtLaunchWhenPrewarmed(isPrewarmed: Bool) throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(
            notificationCenter: NotificationCenter(),
            readState: SystemValues().read,
            launchDate: Date(timeIntervalSinceNow: -60),
            isPrewarmed: isPrewarmed,
            deliveryQueue: queue
        )
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        #expect(Self.history(toldBy: tracker, queue: queue).map(\.kind) == [isPrewarmed ? .launch : .start])
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

        #expect(Self.history(toldBy: tracker, queue: queue).map(\.kind) == [.launch])
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

        #expect(Self.history(toldBy: tracker, queue: queue).map(\.kind) == [.launch, .change])
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
        let system = SystemValues()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: system.read, launchDate: Date(), deliveryQueue: queue)
        let boldText = try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [AccessibilityTrackingObject(type: .boldText)]
        )
        let reconfigurations = EmissionCounter()
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(
                        type: .voiceOver,
                        // VoiceOver is on only in the change, so this
                        // reconfigures while the change's snapshot is taken.
                        transform: { [weak tracker] value in
                            if value == .flag(true) {
                                reconfigurations.increment()
                                tracker?.configureAccessibilityTracking(with: boldText)
                            }
                            return value
                        }
                    )
                ]
            )
        )

        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        system.values[.voiceOver] = .flag(true)
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(reconfigurations.count == 1)
        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Registering a listener that is already registered must not make it
    /// a second recipient of every delivery.
    ///
    @Test("Tells a listener added twice only once")
    func tellsAListenerAddedTwiceOnlyOnce() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)
        tracker.addListener(listener)
        queue.run()

        #expect(listener.snapshots.count == 1)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(listener.snapshots.count == 2)
        withExtendedLifetime(tracker) { }
    }

    @Test("Delivers the current snapshot to a newly added listener")
    func deliversCurrentSnapshotToANewListener() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let listener = SpyListener()
        tracker.addListener(listener)

        // Never inside the registration call, as for the app's completion.
        #expect(listener.snapshots.isEmpty)

        queue.run()

        #expect(listener.snapshots.count == 1)
        #expect(listener.snapshots.first?.states.first?.type == .voiceOver)
        withExtendedLifetime(tracker) { }
    }

    @Test("Notifies listeners on every change")
    func notifiesListenersOnEveryChange() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(listener.snapshots.count == 2)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Cancelling an observation drops what was in flight for it, but the
    /// kit's UI is not an observation: the change it was registered for
    /// when the change happened still reaches it.
    ///
    @Test("Still notifies listeners of a change in flight when an observation is cancelled")
    func notifiesListenersAcrossCancelledObservation() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let first = EmissionCounter()
        let listener = SpyListener()
        let observation = tracker.observeAccessibilityTracking { _ in first.increment() }
        tracker.addListener(listener)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        observation.cancel()
        queue.run()

        #expect(first.count == 1)
        #expect(listener.snapshots.count == 2)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A delivery reaches the completion first and the listeners after it,
    /// in one turn. A completion that reconfigures tracking makes the
    /// snapshot stale for everyone after it, so the listeners must get only
    /// the refresh for the new configuration, never the stale snapshot.
    ///
    @Test("Drops a change for listeners when the completion reconfigures tracking")
    func dropsChangeForListenersWhenCompletionReconfigures() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)

        let boldText = try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [AccessibilityTrackingObject(type: .boldText)]
        )
        let calls = EmissionCounter()
        // Reconfigures when handed the change, not its first snapshot, so the
        // reconfiguration lands between the completion and the listeners.
        let observation = tracker.observeAccessibilityTracking { [weak tracker] _ in
            calls.increment()
            guard calls.count == 2 else { return }
            tracker?.configureAccessibilityTracking(with: boldText)
        }
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(calls.count == 2)
        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The change, the reconfiguration and the second change all happen
    /// before the queue runs, so the stale snapshot, the reconfiguration's
    /// refresh and the second change are all pending before any is
    /// delivered. Had the stale snapshot been delivered, it would have been
    /// the second.
    ///
    @Test("Drops a listener's snapshot from a replaced configuration")
    func dropsListenerSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)
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

        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText], [.boldText]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The listener's counterpart of "Drops a first snapshot taken
    /// under a configuration that has since been replaced": its first
    /// snapshot is scheduled on its own path.
    ///
    @Test("Drops a listener's first snapshot from a replaced configuration")
    func dropsListenerFirstSnapshotFromReplacedConfiguration() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)
        queue.run()

        // The reconfiguration's refresh, then the change; never the stale first.
        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.boldText], [.boldText]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The monitor UI must not keep showing rows for features that are no
    /// longer tracked, and under `.initial` no change would ever replace
    /// them. The app's completion gets nothing from the reconfiguration.
    ///
    @Test("Refreshes listeners, and only them, when tracking is reconfigured")
    func refreshesListenersOnReconfiguration() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let counter = EmissionCounter()
        let observation = tracker.observeAccessibilityTracking { counter.record($0) }
        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .initial,
                objects: [AccessibilityTrackingObject(type: .boldText)]
            )
        )
        queue.run()

        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.boldText]])
        #expect(counter.emittedTypes == [[.voiceOver]])
        withExtendedLifetime((tracker, observation)) { }
    }

    ///
    /// The refresh goes through the same delivery as everything else: never
    /// inside the reconfiguring call, and dropped if tracking is reconfigured
    /// again before it lands, so two reconfigurations in one turn leave the
    /// listener with one refresh, for the second.
    ///
    @Test("Refreshes listeners asynchronously, once for the last of several reconfigurations")
    func refreshesListenersOnceForTheLastReconfiguration() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)
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

        #expect(listener.snapshots.count == 1)

        queue.run()

        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.voiceOver], [.reduceMotion]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A change is handed to the listeners registered when it was scheduled,
    /// so a listener added while it is in flight gets only its own first
    /// snapshot. A listener registered beforehand makes sure the change is
    /// scheduled at all: with nobody to receive it, none would be.
    ///
    @Test("Leaves a change already in flight out of a listener added after it")
    func leavesInFlightChangeOutOfALaterListener() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let earlier = SpyListener()
        tracker.addListener(earlier)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        let later = SpyListener()
        tracker.addListener(later)
        queue.run()

        #expect(earlier.snapshots.count == 2)
        #expect(later.snapshots.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// A monitor opened before tracking is configured stays empty, and is
    /// filled in by the refresh once tracking is configured.
    ///
    @Test("Fills in a listener added before tracking is configured")
    func fillsInAListenerAddedBeforeConfiguration() async throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)

        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        #expect(listener.snapshots.isEmpty)

        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))
        queue.run()

        #expect(listener.snapshots.map { $0.states.map(\.type) } == [[.voiceOver]])
        withExtendedLifetime(tracker) { }
    }

    ///
    /// The monitor UI is held to the fetch type like the completion is:
    /// under `.initial` it keeps the values from when it was presented.
    ///
    @Test("Does not notify a listener of a change when fetching once")
    func doesNotNotifyListenerForInitialFetch() async throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))

        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        #expect(listener.snapshots.count == 1)
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Configured, so the listener's first snapshot is still in flight when
    /// it is let go: the pending delivery must not hold it either.
    ///
    @Test("Does not retain its listeners")
    func doesNotRetainListeners() throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
        weak var released: SpyListener?

        do {
            let listener = SpyListener()
            released = listener
            tracker.addListener(listener)
        }

        #expect(released == nil)
        withExtendedLifetime(tracker) { }
    }

    // MARK: - What the kit is told

    ///
    /// The history holds the system's values, but the kit is told what the
    /// app reports. A transform that folds two text sizes into one flag must
    /// not turn a step between them into a change.
    ///
    @Test("Tells the kit each feature's history through its transform")
    func tellsTheHistoryThroughTheTransform() throws {
        let center = NotificationCenter()
        let system = SystemValues()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: system.read, launchDate: Date(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(
                        type: .fontScale,
                        customIdentifier: "large_text",
                        transform: { .flag(($0.scaleValue ?? 1) >= 1.2) }
                    )
                ]
            )
        )
        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        // Large to extra large: still not large text.
        system.values[.fontScale] = .scale(19.0 / 17)
        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        queue.run()

        let folded = listener.updates.last?.histories["large_text"]
        #expect(folded?.map(\.kind) == [.launch])
        #expect(folded?.map(\.value) == [.flag(false)])

        // Then to an accessibility size: now it is.
        system.values[.fontScale] = .scale(40.0 / 17)
        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        queue.run()

        let changed = listener.updates.last?.histories["large_text"]
        #expect(changed?.map(\.kind) == [.launch, .change])
        #expect(changed?.map(\.value) == [.flag(false), .flag(true)])
    }

    ///
    /// Working out the histories runs the app's transforms over everything
    /// recorded, which only the kit needs. An app that never opens the kit
    /// pays for one transform per snapshot, as without the kit.
    ///
    @Test("Runs the history's transforms only while the kit listens")
    func runsHistoryTransformsOnlyForTheKit() throws {
        let center = NotificationCenter()
        let system = SystemValues()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: system.read, launchDate: Date(), deliveryQueue: queue)
        let transformCalls = EmissionCounter()
        tracker.configureAccessibilityTracking(with: try Self.configuration(countingTransformsIn: transformCalls))

        let observation = tracker.observeAccessibilityTracking { _ in }
        queue.run()
        system.values[.voiceOver] = .flag(true)
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        // One per snapshot: the first, then the change's.
        #expect(transformCalls.count == 2)
        withExtendedLifetime(observation) { }
    }

    ///
    /// A recorded value goes through its transform once per configuration,
    /// not once per delivery: the history only grows. Reconfiguring may
    /// change the transforms, so it starts over.
    ///
    @Test("Transforms each recorded value once per configuration")
    func transformsEachRecordedValueOncePerConfiguration() throws {
        let center = NotificationCenter()
        let system = SystemValues()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, readState: system.read, launchDate: Date(), deliveryQueue: queue)
        let transformCalls = EmissionCounter()
        let configuration = try Self.configuration(countingTransformsIn: transformCalls)
        tracker.configureAccessibilityTracking(with: configuration)

        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()

        // The snapshot, and the launch value in the history.
        #expect(transformCalls.count == 2)

        system.values[.voiceOver] = .flag(true)
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()

        // The snapshot, and only the new change: the launch value is known.
        #expect(transformCalls.count == 4)

        tracker.configureAccessibilityTracking(with: configuration)
        queue.run()

        // The refresh's snapshot, and both recorded values again.
        #expect(transformCalls.count == 7)
        withExtendedLifetime(tracker) { }
    }

    @Test("Tells the kit the tracking status and why each update came")
    func tellsTheStatusAndTheReason() throws {
        let center = NotificationCenter()
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: center, deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))

        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()
        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        queue.run()
        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))
        queue.run()
        tracker.configureAccessibilityTracking(with: try AccessibilityTrackingConfiguration(fetchType: .continuous, objects: []))
        queue.run()

        let updates = listener.updates
        #expect(updates.map(\.reason) == [.registration, .change, .reconfiguration, .reconfiguration])
        #expect(updates.map(\.status).prefix(2) == [.live, .live])
        #expect(updates.count == 4)
        if updates.count == 4 {
            // A one-time read is dated by its snapshot.
            #expect(updates[2].status == .snapshot(updates[2].snapshot.date))
            #expect(updates[3].status == .notTracked)
        }
        withExtendedLifetime(tracker) { }
    }

    ///
    /// Read when a screen opens, before its first update lands, so a
    /// tracked app never flashes the nothing-tracked screen.
    ///
    @Test("Reports its tracking status before anything is delivered")
    func reportsTheStatusBeforeAnyDelivery() throws {
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: ManualDeliveryQueue())

        #expect(tracker.trackingStatus == .notTracked)

        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .continuous))
        #expect(tracker.trackingStatus == .live)

        tracker.configureAccessibilityTracking(with: try Self.configuration(fetchType: .initial))
        guard case .snapshot = tracker.trackingStatus else {
            Issue.record("Expected a snapshot status, got \(tracker.trackingStatus)")
            return
        }

        tracker.configureAccessibilityTracking(with: try AccessibilityTrackingConfiguration(fetchType: .continuous, objects: []))
        #expect(tracker.trackingStatus == .notTracked)
    }
}

// MARK: - Helpers

private extension AccessibilityTrackerTests {

    ///
    /// A feature's history as the kit is told it: a listener registers, the
    /// queue runs, and the history in its update comes back.
    ///
    static func history(
        toldBy tracker: AccessibilityTracker,
        queue: ManualDeliveryQueue,
        for identifier: String = "voice_over"
    ) -> [AccessibilityHistoryEntry] {
        let listener = SpyListener()
        tracker.addListener(listener)
        queue.run()
        return listener.updates.last?.histories[identifier] ?? []
    }

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

// MARK: - Spies

// `NotificationCenter` is `@unchecked Sendable`, so a subclass has to restate
// it. The spy is only ever touched from the test that owns it.
private final class SpyNotificationCenter: NotificationCenter, @unchecked Sendable {

    private(set) var addedObservers = [ObjectIdentifier]()
    private(set) var removedObservers = [ObjectIdentifier]()

    override func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        addedObservers.append(ObjectIdentifier(observer as AnyObject))
        super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
    }

    override func removeObserver(_ observer: Any) {
        removedObservers.append(ObjectIdentifier(observer as AnyObject))
        super.removeObserver(observer)
    }
}

///
/// Records every update delivered to it.
///
@MainActor
private final class SpyListener: TrackerListener {

    private(set) var updates = [TrackerUpdate]()

    var snapshots: [AccessibilitySnapshot] {
        return updates.map(\.snapshot)
    }

    func trackerDidUpdate(_ update: TrackerUpdate) {
        updates.append(update)
    }
}
