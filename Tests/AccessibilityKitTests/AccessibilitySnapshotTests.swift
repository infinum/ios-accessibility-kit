//
//  AccessibilitySnapshotTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@Suite("AccessibilitySnapshot")
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
    /// `values` is an **array** of `{ identifier, value }` objects, not a
    /// dictionary keyed by identifier. Pinning it here because the README
    /// currently documents the wrong shape.
    ///
    @Test("Converts to a dictionary holding an array of identified values")
    func convertsToDictionary() throws {
        let snapshot = AccessibilitySnapshot(
            states: [
                AccessibilityState(type: .boldText, name: "Bold Text", value: .flag(true)),
                AccessibilityState(
                    type: .fontScale, name: "Font scale", value: .scale(1.25),
                    customIdentifier: "font_scalling"
                )
            ]
        )

        let values = try #require(snapshot.toDictionary()?["values"] as? [[String: Any]])

        #expect(values.count == 2)
        #expect(values.first?["identifier"] as? String == "bold_text")
        #expect(values.first?["value"] as? Bool == true)
        #expect(values.last?["identifier"] as? String == "font_scalling")
        #expect(values.last?["value"] as? Double == 1.25)
    }
}
