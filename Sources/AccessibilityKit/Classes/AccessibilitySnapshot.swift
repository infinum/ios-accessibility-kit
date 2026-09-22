//
//  AccessibilitySnapshot.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

public struct AccessibilitySnapshot {

    public let states: [AccessibilityState]

    public init(states: [AccessibilityState]) {
        self.states = states.sorted()
    }

    init(trackingObjects: [AccessibilityTrackingObject]) {
        self.init(
            states: trackingObjects.map { trackingObject in
                let state = AccessibilityObjectFactory
                    .object(for: trackingObject.type)
                    .state(customIdentifier: trackingObject.customIdentifier)

                guard let transform = trackingObject.transform else { return state }
                return state.withValue(transform(state.value))
            }
        )
    }
}

extension AccessibilitySnapshot: Encodable {

    enum CodingKeys: String, CodingKey {
        case states = "values"
    }
}
