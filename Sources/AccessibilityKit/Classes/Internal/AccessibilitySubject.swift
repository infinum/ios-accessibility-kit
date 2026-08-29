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
    private var observers = [Observer]()

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
        observers.append(observer)
    }

    func removeObserver(_ observer: Observer) {
        observers.removeAll(where: { $0 === observer })
    }

    func removeObservers() {
        observers.removeAll()
    }
}

// MARK: - Extensions

extension AccessibilitySubject {

    func notifyObservers(with state: AccessibilityState) {
        observers
            .forEach {
                guard let observer = $0 as? AccessibilityObserver else { return }
                observer.accessibilityStateDidChange(state)
            }
    }
}
