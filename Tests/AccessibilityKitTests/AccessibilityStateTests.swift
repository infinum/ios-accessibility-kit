//
//  AccessibilityStateTests.swift
//  AccessibilityKitTests
//

import Foundation
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
            name: "Font Scale",
            value: .scale(1.0)
        )

        #expect(state.withValue(value).value == value)
    }

    @Test("withValue preserves type, name and the default identifier")
    func withValuePreservesIdentity() {
        let state = AccessibilityState(
            type: .fontScale,
            name: "Font Scale",
            value: .scale(1.29)
        )

        let corrected = state.withValue(.flag(true))

        #expect(corrected.type == .fontScale)
        #expect(corrected.name == "Font Scale")
        #expect(corrected.identifier == "font_scale")
    }

    @Test("withValue preserves a custom identifier")
    func withValuePreservesCustomIdentifier() {
        let state = AccessibilityState(
            type: .fontScale,
            name: "Font Scale",
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

        let data = try JSONEncoder().encode(state)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["identifier"] as? String == "custom")
        #expect(json?.count == 2)
        switch fixture.value {
        case .flag(let value):
            // Decoded rather than cast: `as? Bool` also accepts a JSON 0 or 1,
            // while JSONDecoder only accepts a JSON boolean.
            #expect(try JSONDecoder().decode(FlagPayload.self, from: data).value == value)
        case .number(let value), .scale(let value), .percentage(let value):
            #expect(json?["value"] as? Double == value)
        }
    }
}

private struct FlagPayload: Decodable {
    let value: Bool
}
