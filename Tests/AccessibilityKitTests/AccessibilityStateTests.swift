//
//  AccessibilityStateTests.swift
//  AccessibilityKitTests
//

import Testing
@testable import AccessibilityKit

@Suite("AccessibilityState")
struct AccessibilityStateTests {

    @Test(
        "withValue replaces the value",
        arguments: [
            AccessibilityValue.flag(true),
            .number(42),
            .scale(1.5),
            .percentage(0.25)
        ]
    )
    func withValueReplacesValue(value: AccessibilityValue) {
        let state = AccessibilityState(
            type: .fontScale,
            name: "Font scale",
            value: .scale(1.0)
        )

        #expect(state.withValue(value).value == value)
    }

    @Test("withValue preserves type, name and the default identifier")
    func withValuePreservesIdentity() {
        let state = AccessibilityState(
            type: .fontScale,
            name: "Font scale",
            value: .scale(1.29)
        )

        let corrected = state.withValue(.flag(true))

        #expect(corrected.type == .fontScale)
        #expect(corrected.name == "Font scale")
        #expect(corrected.identifier == "font_scale")
    }

    @Test("withValue preserves a custom identifier")
    func withValuePreservesCustomIdentifier() {
        let state = AccessibilityState(
            type: .fontScale,
            name: "Font scale",
            value: .scale(1.29),
            customIdentifier: "large_text_enabled"
        )

        #expect(state.withValue(.flag(true)).identifier == "large_text_enabled")
    }
}
