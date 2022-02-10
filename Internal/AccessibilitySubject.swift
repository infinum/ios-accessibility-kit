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

@objc
class AccessibilitySubject: NSObject {

    // MARK: - Internal properties

    private var observers = [Observer]()

    // MARK: - Lifecycle

    init(notificationName: Notification.Name) {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityDidChange(_:)),
            name: notificationName,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Internal methods

    @objc
    func accessibilityDidChange(_ notification: Notification) {
        fatalError("Method `accessibilityDidChange(_:)` should be implemented in the subclass.")
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

    func publish(state: AccessibilityState) {
        observers
            .forEach {
                guard let observer = $0 as? AccessibilityObserver else { return }
                observer.accessibilityStateDidChange(state)
            }
    }
}
