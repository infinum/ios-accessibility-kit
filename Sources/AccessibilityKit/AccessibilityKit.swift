//
//  AccessibilityKit.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

public final class AccessibilityKit: AccessibilityObserver {

    // MARK: - Public properties

    public static let shared = AccessibilityKit()

    // MARK: - Private properties

    private var accessibilityObjects = [AccessibilityObject]()

    private var stateChangesCompletion: (([AccessibilityState]) -> Void)?

    // MARK: - Lifecycle

    private init() { }

    // MARK: - Public methods

    public func configureTracking(for accessibilityTypes: AccessibilityType...) {
        accessibilityObjects.forEach { $0.removeObservers() }

        accessibilityObjects = accessibilityTypes
            .compactMap(AccessibilityObjectFactory.object(for:))
        accessibilityObjects.forEach { $0.addObserver(self) }
    }

    public func observeStateChanges(completion: @escaping ([AccessibilityState]) -> Void) {
        stateChangesCompletion = completion
        stateChangesCompletion?(accessibilityObjects)
    }
}

// MARK: - AccessibilityObserver

extension AccessibilityKit {

    func accessibilityStateDidChange(_ accessibilityState: AccessibilityState) {
        guard let oldObject = accessibilityObjects.first(where: { $0.type == accessibilityState.type }) else {
            return
        }
        oldObject.removeObserver(self)
        accessibilityObjects.removeAll(where: { $0.type == oldObject.type })

        guard let newObject = AccessibilityObjectFactory.object(for: accessibilityState.type) else { return }
        newObject.addObserver(self)
        accessibilityObjects.append(newObject)

        stateChangesCompletion?(accessibilityObjects)
    }
}
