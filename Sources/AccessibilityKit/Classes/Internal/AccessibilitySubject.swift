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
        removeReleasedObservers()
        guard !observers.contains(where: { $0.observer === observer }) else { return }
        observers.append(WeakObserver(observer: observer))
    }

    func removeObserver(_ observer: Observer) {
        observers.removeAll(where: { $0.observer === observer || $0.observer == nil })
    }

    func removeObservers() {
        observers.removeAll()
    }
}

// MARK: - Extensions

extension AccessibilitySubject {

    func notifyObservers(with state: AccessibilityState) {
        observers
            .compactMap { $0.observer as? AccessibilityObserver }
            .forEach { $0.accessibilityStateDidChange(state) }
    }
}

// MARK: - Private methods

private extension AccessibilitySubject {

    ///
    /// Called only from registration, which the monitor performs on its
    /// barrier queue. Notification delivery must not sweep: it runs on the
    /// posting thread, and writing `observers` from there would race the
    /// registration writes. Released observers are skipped when notifying,
    /// so the sweep is only there to stop empty boxes accumulating.
    ///
    func removeReleasedObservers() {
        observers.removeAll(where: { $0.observer == nil })
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
