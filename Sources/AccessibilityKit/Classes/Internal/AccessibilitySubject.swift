//
//  AccessibilitySubject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

@MainActor
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
@MainActor
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

    ///
    /// `NotificationCenter` dispatches this selector on whichever thread
    /// posted, so it cannot be main-actor isolated by declaration. UIKit
    /// posts its accessibility status notifications on the main thread, which
    /// is the path that matters and is handled without a hop, so an observer
    /// sees the change in the same turn.
    ///
    /// A post from any other thread is carried to the main actor instead of
    /// trapping there. The registration is on a notification centre the
    /// library does not own, so anything in the process can post these names
    /// from anywhere, and `MainActor.assumeIsolated` would make that somebody
    /// else's background post a crash in a shipped app.
    ///
    @objc
    nonisolated func accessibilityStateDidChange(_ notification: Notification) {
        guard Thread.isMainThread else {
            Task { @MainActor [weak self] in self?.readStateAndNotify() }
            return
        }

        MainActor.assumeIsolated { readStateAndNotify() }
    }

    private func readStateAndNotify() {
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

// MARK: - Private methods

private extension AccessibilitySubject {

    ///
    /// A released observer is skipped rather than swept out of the list:
    /// pruning belongs to registration, and the monitor registers exactly
    /// once per subject.
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
