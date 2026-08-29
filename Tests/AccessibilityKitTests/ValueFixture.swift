//
//  ValueFixture.swift
//  AccessibilityKitTests
//

@testable import AccessibilityKit

///
/// Swift Testing requires `arguments:` elements to be `Sendable`.
/// `AccessibilityValue` is public and so gets no implicit `Sendable`
/// conformance; adding one belongs to the Swift 6 migration, not here.
/// This payload-free enum stands in for it in parameterised tests.
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
