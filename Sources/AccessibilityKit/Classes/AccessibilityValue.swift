//
//  AccessibilityValue.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 04.04.2022..
//

import Foundation

public enum AccessibilityValue {
    case flag(Bool)
    case number(Double)
    case scale(Double)
    case percentage(Double)
}

extension AccessibilityValue: Equatable {

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

    var flagValue: Bool {
        if case .flag(let isOn) = self {
            return isOn
        }
        return false
    }

    var numberValue: Double? {
        if case .number(let number) = self {
            return number
        }
        return nil
    }

    var scaleValue: Double? {
        if case .scale(let scale) = self {
            return scale
        }
        return nil
    }

    var percentageValue: Double? {
        if case .percentage(let percentage) = self {
            return percentage
        }
        return nil
    }
}
