//
//  AccessibilitySnapshot.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

public struct AccessibilitySnapshot {

    public let states: [AccessibilityState]

    init(states: [AccessibilityState]) {
        self.states = states.sorted()
    }

    init(trackingObjects: [AccessibilityTrackingObject]) {
        self.states = trackingObjects.map {
            AccessibilityObjectFactory
                .object(for: $0.type)
                .state(customIdentifier: $0.customIdentifier)
        }
    }

    func toDictionary() -> [String: Any] {
        // TODO: Add the implementation for returning the dictionary from accessibility states.
        return [:]
    }

}
