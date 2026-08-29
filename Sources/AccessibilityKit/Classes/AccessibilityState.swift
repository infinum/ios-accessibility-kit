//
//  AccessibilityState.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation
import UIKit

///
/// The state of a single accessibility feature at the moment it was read.
///
/// ## Discussion
///
/// States are produced by the library, never constructed by a consumer. To
/// adjust one, use ``withValue(_:)``, which preserves the feature's identity.
///
/// Two states are equal when their ``type`` and ``value`` match; ``name`` and
/// ``identifier`` are ignored. Sorting orders them by the type's raw value.
///
public struct AccessibilityState {

    // MARK: - Public methods

    /// The accessibility feature this state describes.
    public let type: AccessibilityType

    /// A human-readable name for the feature, suitable for display.
    public let name: String

    /// The value the feature reported.
    public let value: AccessibilityValue

    ///
    /// The identifier the feature is reported under.
    ///
    /// This is the custom identifier supplied on the tracking object, or the
    /// ``type``'s raw value when none was given. Each entry in the encoded
    /// output carries it alongside the value, so it is how a feature is found
    /// in the payload.
    ///
    public let identifier: String

    // MARK: - Lifecycle

    init(
        type: AccessibilityType,
        name: String,
        value: AccessibilityValue,
        customIdentifier: String? = nil
    ) {
        self.type = type
        self.name = name
        self.value = value
        self.identifier = customIdentifier ?? type.rawValue
    }
}

// MARK: - Encodable

extension AccessibilityState: Encodable {

    enum CodingKeys: String, CodingKey {
        case identifier, value
    }

    ///
    /// Encodes the state as its ``identifier`` and the payload of its
    /// ``value``.
    ///
    /// The value's case is not written — a ``AccessibilityValue/flag(_:)``
    /// encodes as a boolean and the numeric cases as a number, so the output
    /// carries only `identifier` and `value`.
    ///
    /// - Parameter encoder: The encoder to write to.
    /// - Throws: Any error the encoder throws.
    ///
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
    
    ///
    /// Compares two states by ``type`` and ``value`` only.
    ///
    /// ``name`` and ``identifier`` are deliberately ignored, so the same
    /// feature reporting the same value is equal regardless of the identifier
    /// it happens to be reported under.
    ///
    public static func == (lhs: AccessibilityState, rhs: AccessibilityState) -> Bool {
        return lhs.type == rhs.type && lhs.value == rhs.value
    }
}

// MARK: - Comparable

extension AccessibilityState: Comparable {

    ///
    /// Orders states by the raw value of their ``type``, so a snapshot's
    /// states always appear in a stable, predictable order.
    ///
    public static func < (lhs: AccessibilityState, rhs: AccessibilityState) -> Bool {
        return lhs.type.rawValue < rhs.type.rawValue
    }
}

// MARK: - Identifiable

extension AccessibilityState: Identifiable {

    ///
    /// The state's ``identifier``, used as its identity in SwiftUI lists.
    ///
    public var id: String { identifier }
}

// MARK: - Value transformation

public extension AccessibilityState {

    ///
    /// Returns a copy of the state carrying a different value.
    ///
    /// Use this to correct a value that has already been produced — for
    /// example, to record a font scale as a plain "large text is enabled"
    /// flag:
    ///
    /// ```swift
    /// let corrected = state.withValue(.flag((state.value.scaleValue ?? 1) >= 1.2))
    /// ```
    ///
    /// ## Discussion
    ///
    /// The ``type``, ``name`` and ``identifier`` are preserved, so a corrected
    /// state keeps identifying the same accessibility feature. Only the value
    /// can be replaced, so the identifier can never drift away from the type
    /// it was derived from.
    ///
    /// To correct a value everywhere it is reported — snapshots, observed
    /// changes, the encoded output and the accessibility monitor alike — pass
    /// a transform to
    /// ``AccessibilityTrackingObject/init(type:customIdentifier:transform:)``
    /// instead of applying this at each call site.
    ///
    /// - Parameter value: The value the returned state should carry.
    /// - Returns: A copy of the state with `value` replaced.
    ///
    func withValue(_ value: AccessibilityValue) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: value,
            customIdentifier: identifier
        )
    }
}
