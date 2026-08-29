//
//  AccessibilityValueTests.swift
//  AccessibilityKitTests
//

import Testing
@testable import AccessibilityKit

@Suite("AccessibilityValue")
struct AccessibilityValueTests {

    @Test("Equals itself", arguments: ValueFixture.allCases)
    func equalsItself(fixture: ValueFixture) {
        #expect(fixture.value == fixture.value)
    }

    @Test("Differs from every other case", arguments: ValueFixture.allCases)
    func differsAcrossCases(fixture: ValueFixture) {
        let others = ValueFixture.allCases.filter { $0 != fixture }

        for other in others {
            #expect(fixture.value != other.value)
        }
    }

    @Test("Differs from the same case carrying another payload")
    func differsWithinCase() {
        #expect(AccessibilityValue.flag(true) != .flag(false))
        #expect(AccessibilityValue.number(1) != .number(2))
        #expect(AccessibilityValue.scale(1) != .scale(2))
        #expect(AccessibilityValue.percentage(0.1) != .percentage(0.2))
    }

    @Test("Reads the payload of a matching case")
    func readsMatchingPayload() {
        #expect(AccessibilityValue.flag(true).flagValue == true)
        #expect(AccessibilityValue.number(42).numberValue == 42)
        #expect(AccessibilityValue.scale(1.5).scaleValue == 1.5)
        #expect(AccessibilityValue.percentage(0.25).percentageValue == 0.25)
    }

    ///
    /// `flagValue` is not optional: it reports `false` rather than `nil` for a
    /// non-flag value, so a caller cannot distinguish "off" from "not a flag".
    /// The other three accessors return `nil`.
    ///
    @Test("Reports false, not nil, when reading a flag from another case")
    func readsFlagFromMismatchedCase() {
        #expect(AccessibilityValue.number(42).flagValue == false)
        #expect(AccessibilityValue.scale(1.5).flagValue == false)
        #expect(AccessibilityValue.percentage(0.25).flagValue == false)
    }

    @Test("Returns nil when reading a numeric payload from another case")
    func readsNumericFromMismatchedCase() {
        #expect(AccessibilityValue.flag(true).numberValue == nil)
        #expect(AccessibilityValue.flag(true).scaleValue == nil)
        #expect(AccessibilityValue.flag(true).percentageValue == nil)
        #expect(AccessibilityValue.number(42).scaleValue == nil)
        #expect(AccessibilityValue.scale(1.5).numberValue == nil)
        #expect(AccessibilityValue.percentage(0.25).numberValue == nil)
    }
}
