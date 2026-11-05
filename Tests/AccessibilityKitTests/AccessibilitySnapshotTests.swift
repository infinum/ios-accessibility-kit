//
//  AccessibilitySnapshotTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@Suite("AccessibilitySnapshot")
@MainActor
struct AccessibilitySnapshotTests {

    @Test("Sorts states produced from tracking objects")
    func sortsStatesFromTrackingObjects() {
        let snapshot = AccessibilitySnapshot(
            trackingObjects: [
                AccessibilityTrackingObject(type: .voiceOver),
                AccessibilityTrackingObject(type: .boldText)
            ]
        )

        #expect(snapshot.states.map(\.type) == [.boldText, .voiceOver])
    }

    @Test("Applies a tracking object's transform to the produced value")
    func appliesTransform() {
        let snapshot = AccessibilitySnapshot(
            trackingObjects: [
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { value in .flag(value.scaleValue != nil) }
                )
            ]
        )

        #expect(snapshot.states.first?.value == .flag(true))
        #expect(snapshot.states.first?.identifier == "large_text_enabled")
    }

    @Test("Leaves the value untouched when no transform is supplied")
    func leavesValueUntouchedWithoutTransform() {
        let snapshot = AccessibilitySnapshot(
            trackingObjects: [AccessibilityTrackingObject(type: .fontScale)]
        )

        #expect(snapshot.states.first?.value.scaleValue != nil)
    }

    @Test("Applies each transform only to its own tracking object")
    func appliesTransformPerObject() {
        let snapshot = AccessibilitySnapshot(
            trackingObjects: [
                AccessibilityTrackingObject(
                    type: .boldText,
                    transform: { _ in .number(99) }
                ),
                AccessibilityTrackingObject(type: .voiceOver)
            ]
        )

        // The second state's concrete value depends on the host's VoiceOver
        // setting, so assert only that the first object's transform did not
        // reach it.
        #expect(snapshot.states.first?.value == .number(99))
        #expect(snapshot.states.last?.value.numberValue == nil)
    }

    @Test("Transformed values reach the encoded output without changing its shape")
    func transformReachesEncodedOutput() throws {
        let snapshot = AccessibilitySnapshot(
            trackingObjects: [
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { _ in .flag(false) }
                )
            ]
        )

        let data = try JSONEncoder().encode(snapshot)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let values = try #require(json?["values"] as? [[String: Any]])

        #expect(values.count == 1)
        #expect(values.first?["identifier"] as? String == "large_text_enabled")
        // False rather than true: an untransformed font scale encodes as a
        // number, and JSONSerialization hands it back as an NSNumber that
        // bridges to `true` for any scale of 1.0 - so expecting `true` here
        // would hold whether the transform ran or not.
        #expect(values.first?["value"] as? Bool == false)
    }

    @Test("Sorts states supplied directly")
    func sortsStatesSuppliedDirectly() {
        let snapshot = AccessibilitySnapshot(
            states: [
                AccessibilityState(type: .voiceOver, name: "VoiceOver", value: .flag(false)),
                AccessibilityState(type: .boldText, name: "Bold text", value: .flag(false))
            ]
        )

        #expect(snapshot.states.map(\.type) == [.boldText, .voiceOver])
    }

    ///
    /// Both orders are tried, so the result cannot be the supplied order
    /// surviving a sort that happens to be stable.
    ///
    @Test("Orders states of one type by identifier", arguments: [false, true])
    func ordersSameTypeStatesByIdentifier(reversed: Bool) {
        let raw = AccessibilityState(type: .fontScale, name: "Font scale", value: .scale(1.2))
        let corrected = AccessibilityState(
            type: .fontScale, name: "Font scale", value: .flag(true), customIdentifier: "a_large_text"
        )
        let supplied = [raw, corrected]

        let snapshot = AccessibilitySnapshot(states: reversed ? supplied.reversed() : supplied)

        #expect(snapshot.states.map(\.identifier) == ["a_large_text", "font_scale"])
    }

    ///
    /// The identifiers sort the opposite way to the types, so a sort by
    /// identifier alone would fail: the identifier only breaks ties between
    /// states of the same type.
    ///
    @Test("Orders states by type before identifier")
    func ordersByTypeBeforeIdentifier() {
        let snapshot = AccessibilitySnapshot(
            states: [
                AccessibilityState(
                    type: .voiceOver, name: "VoiceOver", value: .flag(false), customIdentifier: "a_voice_over"
                ),
                AccessibilityState(
                    type: .boldText, name: "Bold text", value: .flag(false), customIdentifier: "z_bold_text"
                )
            ]
        )

        #expect(snapshot.states.map(\.type) == [.boldText, .voiceOver])
    }

    ///
    /// `values` is an **array** of `{ identifier, value }` objects, not a
    /// dictionary keyed by identifier.
    ///
    @Test("Converts to a dictionary holding an array of identified values")
    func convertsToDictionary() throws {
        let snapshot = AccessibilitySnapshot(
            states: [
                AccessibilityState(type: .boldText, name: "Bold Text", value: .flag(true)),
                AccessibilityState(
                    type: .fontScale, name: "Font Scale", value: .scale(1.25),
                    customIdentifier: "font_scaling"
                )
            ]
        )

        let values = try #require(try snapshot.toDictionary()["values"] as? [[String: Any]])

        #expect(values.count == 2)
        #expect(values.first?["identifier"] as? String == "bold_text")
        #expect(values.first?["value"] as? Bool == true)
        #expect(values.last?["identifier"] as? String == "font_scaling")
        #expect(values.last?["value"] as? Double == 1.25)
    }

    ///
    /// `JSONEncoder` rejects a non-finite number, and the conversion must
    /// pass that on rather than hand back an empty or partial dictionary.
    ///
    @Test("Throws the encoder's error for a value it cannot encode")
    func throwsForNonFiniteValue() {
        let snapshot = AccessibilitySnapshot(
            states: [
                AccessibilityState(type: .fontScale, name: "Font Scale", value: .scale(.nan))
            ]
        )

        #expect(throws: EncodingError.self) {
            try snapshot.toDictionary()
        }
    }
}
