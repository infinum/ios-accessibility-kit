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
        self.states = states.sorted(by: { left, right in left.name < right.name })
    }

    func toDictionary() -> [String: Any] {
        // TODO: Add the implementation for returning the dictionary from accessibility states.
        return [:]
    }

}
