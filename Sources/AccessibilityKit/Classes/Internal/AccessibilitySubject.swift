//
//  AccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

protocol Subject: AnyObject {
    func addObserver(_ observer: Observer)
    func removeObserver(_ observer: Observer)
    func removeObservers()
}

///
/// Watches one accessibility feature and fans its changes out to observers.
///
/// One subject exists per tracked ``AccessibilityType``. It listens for that
/// feature's system notification and, on each one, reads a fresh state and
/// hands it to every registered observer.
///
/// Observers are held weakly, so a subject never keeps its listeners alive.
///
class AccessibilitySubject {

    // MARK: - Internal properties

    private let object: AccessibilityObject
    private let notificationCenter: NotificationCenter
    private var observers = [WeakObserver]()

    // MARK: - Lifecycle

    init(type: AccessibilityType, notificationCenter: NotificationCenter = .default) {
        self.object = AccessibilityObjectFactory.object(for: type)
        self.notificationCenter = notificationCenter

        notificationCenter.addObserver(
            self,
            selector: #selector(accessibilityStateDidChange(_:)),
            name: object.notificationName,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Internal methods

    @objc
    func accessibilityStateDidChange(_ notification: Notification) {
        notifyObservers(with: object.state(customIdentifier: nil))
    }
}

// MARK: - Subject

extension AccessibilitySubject: Subject {

    func addObserver(_ observer: Observer) {
        guard !observers.contains(where: { $0.observer === observer }) else { return }
        observers.append(WeakObserver(observer: observer))
    }

    func removeObserver(_ observer: Observer) {
        observers.removeAll(where: { $0.observer === observer })
    }

    func removeObservers() {
        observers.removeAll()
    }
}

// MARK: - Extensions

extension AccessibilitySubject {

    ///
    /// Delivery runs on whichever thread posted the notification, while
    /// registration runs on the monitor's queue, so this only reads the
    /// observer list - a released observer is skipped here rather than
    /// swept, which would be a second writer.
    ///
    func notifyObservers(with state: AccessibilityState) {
        observers
            .compactMap { $0.observer as? AccessibilityObserver }
            .forEach { $0.accessibilityStateDidChange(state) }
    }
}

// MARK: - Weak observer

///
/// Observers are held weakly: a subject outlives the objects listening to it,
/// and must not keep them alive.
///
private struct WeakObserver {

    weak var observer: Observer?
}
