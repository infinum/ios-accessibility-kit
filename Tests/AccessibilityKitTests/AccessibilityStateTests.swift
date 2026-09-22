//
//  AccessibilityStateTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@Suite("AccessibilityState")
struct AccessibilityStateTests {

    @Test("withValue replaces the value", arguments: ValueFixture.allCases)
    func withValueReplacesValue(fixture: ValueFixture) {
        let state = AccessibilityState(
            type: .fontScale,
            name: "Font scale",
            value: .scale(1.0)
        )

        #expect(state.withValue(fixture.value).value == fixture.value)
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

    @Test("Equality ignores name and identifier")
    func equalityIgnoresNameAndIdentifier() {
        let one = AccessibilityState(
            type: .voiceOver, name: "VoiceOver", value: .flag(true), customIdentifier: "a"
        )
        let two = AccessibilityState(
            type: .voiceOver, name: "Something else", value: .flag(true), customIdentifier: "b"
        )

        #expect(one == two)
    }

    @Test("Differs when the value differs")
    func differsOnValue() {
        let on = AccessibilityState(type: .voiceOver, name: "VoiceOver", value: .flag(true))
        let off = AccessibilityState(type: .voiceOver, name: "VoiceOver", value: .flag(false))

        #expect(on != off)
    }

    @Test("Differs when the type differs")
    func differsOnType() {
        let voice = AccessibilityState(type: .voiceOver, name: "VoiceOver", value: .flag(true))
        let bold = AccessibilityState(type: .boldText, name: "Bold Text", value: .flag(true))

        #expect(voice != bold)
    }

    ///
    /// The identifiers are chosen to sort the other way round, so ordering
    /// by them instead of by the type would fail this.
    ///
    @Test("Orders by the type's raw value")
    func ordersByTypeRawValue() {
        let bold = AccessibilityState(
            type: .boldText, name: "Bold Text", value: .flag(false), customIdentifier: "z_bold"
        )
        let voice = AccessibilityState(
            type: .voiceOver, name: "VoiceOver", value: .flag(false), customIdentifier: "a_voice"
        )

        #expect(bold < voice)
    }

    @Test("Identifies itself by its identifier")
    func identifiesByIdentifier() {
        let state = AccessibilityState(
            type: .voiceOver, name: "VoiceOver", value: .flag(true), customIdentifier: "custom"
        )

        #expect(state.id == "custom")
    }

    @Test("Encodes the identifier and the unwrapped value", arguments: ValueFixture.allCases)
    func encodesUnwrappedValue(fixture: ValueFixture) throws {
        let state = AccessibilityState(
            type: .voiceOver, name: "VoiceOver", value: fixture.value, customIdentifier: "custom"
        )

        let json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(state)
        ) as? [String: Any]

        #expect(json?["identifier"] as? String == "custom")
        #expect(json?.count == 2)
        switch fixture.value {
        case .flag(let value):
            #expect(json?["value"] as? Bool == value)
        case .number(let value), .scale(let value), .percentage(let value):
            #expect(json?["value"] as? Double == value)
        }
    }
}
