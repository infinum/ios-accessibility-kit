//
//  ValueFixture.swift
//  AccessibilityKitTests
//

@testable import AccessibilityKit

///
/// One payload-free case per `AccessibilityValue` case, for parameterised
/// tests. Telling the cases apart through this enum rather than through
/// `AccessibilityValue`'s own `==` keeps the equality tests from relying on
/// the operator they check.
///
enum ValueFixture: CaseIterable, Equatable, Sendable {
    case flag
    case number
    case scale
    case percentage

    var value: AccessibilityValue {
        switch self {
        case .flag:
            return .flag(true)
        case .number:
            return .number(42)
        case .scale:
            return .scale(1.5)
        case .percentage:
            return .percentage(0.25)
        }
    }
}
