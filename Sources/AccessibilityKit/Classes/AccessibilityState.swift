//
//  AccessibilityState.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation
import UIKit

public struct AccessibilityState {

    // MARK: - Public methods

    public let type: AccessibilityType
    public let name: String
    public let value: AccessibilityValue
    public let identifier: String

    // MARK: - Lifecycle

    init(
        type: AccessibilityType,
        name: String,
        value: AccessibilityValue,
        identifier: String
    ) {
        self.type = type
        self.name = name
        self.value = value
        self.identifier = identifier
    }

    init(
        type: AccessibilityType,
        name: String,
        value: AccessibilityValue,
        customIdentifier: String? = nil
    ) {
        self.init(
            type: type,
            name: name,
            value: value,
            identifier: customIdentifier ?? type.rawValue
        )
    }
}

// MARK: - Encodable

extension AccessibilityState: Encodable {

    enum CodingKeys: String, CodingKey {
        case identifier, value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        switch value {
        case .number(let value), .percentage(let value), .scale(let value):
            try container.encode(value, forKey: .value)
        case .flag(let value):
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - Equatable

extension AccessibilityState: Equatable {
    
    public static func == (lhs: AccessibilityState, rhs: AccessibilityState) -> Bool {
        return lhs.type == rhs.type && lhs.value == rhs.value
    }
}

// MARK: - Comparable

extension AccessibilityState: Comparable {

    public static func < (lhs: AccessibilityState, rhs: AccessibilityState) -> Bool {
        return lhs.type.rawValue < rhs.type.rawValue
    }
}

// MARK: - Identifiable

extension AccessibilityState: Identifiable {

    public var id: String { identifier }
}

// MARK: - Value transformation

public extension AccessibilityState {

    ///
    /// Returns a copy of the state carrying a different value.
    ///
    /// The `type`, `name` and `identifier` are preserved, so a corrected
    /// state keeps identifying the same accessibility feature.
    ///
    func withValue(_ value: AccessibilityValue) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: value,
            identifier: identifier
        )
    }
}
