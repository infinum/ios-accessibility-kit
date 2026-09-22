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
