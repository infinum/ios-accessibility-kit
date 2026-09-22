//
//  AccessibilitySubjectTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

@Suite("AccessibilitySubject")
struct AccessibilitySubjectTests {

    @Test("Notifies a registered observer when the notification is posted")
    func notifiesRegisteredObserver() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let observer = SpyObserver()
        subject.addObserver(observer)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(observer.states.count == 1)
        #expect(observer.states.first?.type == .voiceOver)
    }

    @Test("Notifies every registered observer")
    func notifiesEveryRegisteredObserver() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let first = SpyObserver()
        let second = SpyObserver()
        subject.addObserver(first)
        subject.addObserver(second)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(first.states.count == 1)
        #expect(second.states.count == 1)
    }

    @Test("Keeps notifying the observers that were not removed")
    func keepsNotifyingRemainingObservers() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let removed = SpyObserver()
        let kept = SpyObserver()
        subject.addObserver(removed)
        subject.addObserver(kept)
        subject.removeObserver(removed)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(removed.states.isEmpty)
        #expect(kept.states.count == 1)
    }

    @Test("Stops notifying a removed observer")
    func stopsNotifyingRemovedObserver() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let observer = SpyObserver()
        subject.addObserver(observer)
        subject.removeObserver(observer)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(observer.states.isEmpty)
    }

    @Test("Stops notifying after all observers are removed")
    func stopsNotifyingAfterRemoveAll() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let first = SpyObserver()
        let second = SpyObserver()
        subject.addObserver(first)
        subject.addObserver(second)
        subject.removeObservers()

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(first.states.isEmpty)
        #expect(second.states.isEmpty)
    }

    ///
    /// Every other test here watches VoiceOver, which cannot tell a subject
    /// subscribing to its own feature's notification from one hardcoded to
    /// VoiceOver's. A second feature can.
    ///
    @Test("Subscribes to the notification of the feature it was created for")
    func subscribesToItsOwnFeaturesNotification() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .boldText, notificationCenter: center)
        let observer = SpyObserver()
        subject.addObserver(observer)

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)

        #expect(observer.states.count == 1)
        #expect(observer.states.first?.type == .boldText)
    }

    @Test("Ignores notifications for other accessibility features")
    func ignoresOtherNotifications() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let observer = SpyObserver()
        subject.addObserver(observer)

        center.post(name: UIAccessibility.boldTextStatusDidChangeNotification, object: nil)

        #expect(observer.states.isEmpty)
    }

    ///
    /// The centre is spied on rather than only posted to: Foundation zeroes
    /// its own reference to a deallocated observer, so a subject that never
    /// unregistered would stop delivering anyway and the test would pass
    /// while the contract was broken.
    ///
    @Test("Unregisters from the notification centre when deallocated")
    func unregistersOnDeinit() {
        let center = SpyNotificationCenter()
        let observer = SpyObserver()

        do {
            let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
            subject.addObserver(observer)
        }

        #expect(center.removedObservers == 1)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(observer.states.isEmpty)
    }

    @Test("Notifies an observer once even when it is added twice")
    func notifiesDuplicateObserverOnce() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let observer = SpyObserver()
        subject.addObserver(observer)
        subject.addObserver(observer)

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(observer.states.count == 1)
    }

    @Test("Does not retain its observers")
    func doesNotRetainObservers() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        weak var released: SpyObserver?

        do {
            let observer = SpyObserver()
            released = observer
            subject.addObserver(observer)
        }

        #expect(released == nil)
    }

    ///
    /// The released observer is registered last, so nothing prunes its box
    /// before the notification: this exercises the skip on the delivery
    /// path rather than the pruning on the registration path.
    ///
    @Test("Skips observers that have been released")
    func skipsReleasedObservers() {
        let center = NotificationCenter()
        let subject = AccessibilitySubject(type: .voiceOver, notificationCenter: center)
        let retained = SpyObserver()
        subject.addObserver(retained)

        do {
            subject.addObserver(SpyObserver())
        }

        center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)

        #expect(retained.states.count == 1)
    }
}

// MARK: - Spies

private final class SpyNotificationCenter: NotificationCenter {

    private(set) var removedObservers = 0

    override func removeObserver(_ observer: Any) {
        removedObservers += 1
        super.removeObserver(observer)
    }
}

private final class SpyObserver: AccessibilityObserver {

    private(set) var states = [AccessibilityState]()

    func accessibilityStateDidChange(_ state: AccessibilityState) {
        states.append(state)
    }
}
