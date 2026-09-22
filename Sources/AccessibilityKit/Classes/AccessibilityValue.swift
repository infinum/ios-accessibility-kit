//
//  AccessibilityValue.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 04.04.2022..
//

import Foundation

///
/// The value an accessibility feature reports.
///
/// ## Overview
///
/// Which case a feature produces is fixed by its ``AccessibilityType``: every
/// feature reports a ``flag(_:)`` except ``AccessibilityType/fontScale``,
/// which reports a ``scale(_:)``. The remaining cases exist for values
/// supplied by a consumer, through
/// ``AccessibilityTrackingObject/init(type:customIdentifier:transform:)`` or
/// ``AccessibilityState/withValue(_:)``.
///
/// When encoded, only the payload is written — the case itself is not part of
/// the output.
///
public enum AccessibilityValue {

    /// A setting that is either on or off.
    case flag(Bool)

    /// A plain numeric measurement.
    case number(Double)

    /// A multiplier relative to a default of `1.0`, such as text size.
    case scale(Double)

    /// A proportion, where `1.0` represents 100%.
    case percentage(Double)
}

extension AccessibilityValue: Equatable {

    ///
    /// Compares two values, which are equal only when they are the same case
    /// carrying the same payload. A ``flag(_:)`` never equals a
    /// ``number(_:)``, and ``scale(_:)`` never equals ``percentage(_:)``,
    /// even when the underlying numbers match.
    ///
    public static func == (lhs: AccessibilityValue, rhs: AccessibilityValue) -> Bool {
        switch (lhs, rhs) {
        case let (.flag(lhsValue), .flag(rhsValue)):
            return lhsValue == rhsValue
        case let (.number(lhsValue), .number(rhsValue)):
            return lhsValue == rhsValue
        case let (.scale(lhsValue), .scale(rhsValue)):
            return lhsValue == rhsValue
        case let (.percentage(lhsValue), .percentage(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

public extension AccessibilityValue {

    ///
    /// The payload of a ``flag(_:)``, or `false` for any other case.
    ///
    /// - Returns: Whether the feature is enabled. Note this is **not**
    ///   optional: a non-flag value also reports `false`, so this cannot
    ///   distinguish "off" from "not a flag". Match on the case itself when
    ///   that distinction matters.
    ///
    var flagValue: Bool {
        if case .flag(let isOn) = self {
            return isOn
        }
        return false
    }

    ///
    /// The payload of a ``number(_:)``.
    ///
    /// - Returns: The number, or `nil` if the value is not a number.
    ///
    var numberValue: Double? {
        if case .number(let number) = self {
            return number
        }
        return nil
    }

    ///
    /// The payload of a ``scale(_:)``.
    ///
    /// - Returns: The multiplier, or `nil` if the value is not a scale.
    ///
    var scaleValue: Double? {
        if case .scale(let scale) = self {
            return scale
        }
        return nil
    }

    ///
    /// The payload of a ``percentage(_:)``.
    ///
    /// - Returns: The proportion, or `nil` if the value is not a percentage.
    ///
    var percentageValue: Double? {
        if case .percentage(let percentage) = self {
            return percentage
        }
        return nil
    }
}
