//
//  AccessibilityState.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

public enum AccessibilityValue {
    case flag(Bool)
    case number(Double)
}

public struct AccessibilityChange {
    let type: AccessibilityType
    let value: AccessibilityValue
    let timestamp: Double
}

public struct AccessibilityState {

    public let type: AccessibilityType
    public let identifier: String
    public let value: Codable

    public var name: String { type.rawValue }

    init(type: AccessibilityType, customIdentifier: String? = nil) {
        self.type = type
        self.identifier = customIdentifier ?? type.rawValue
        self.value = true
    }
}
