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
                    transform: { _ in .flag(true) }
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
        #expect(snapshot.states.first?.value.flagValue == false)
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

        #expect(snapshot.states.first?.value == .number(99))
        #expect(snapshot.states.last?.value == .flag(false))
    }

    @Test("Transformed values reach the encoded output without changing its shape")
    func transformReachesEncodedOutput() throws {
        let snapshot = AccessibilitySnapshot(
            trackingObjects: [
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { _ in .flag(true) }
                )
            ]
        )

        let data = try JSONEncoder().encode(snapshot)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let values = try #require(json?["values"] as? [[String: Any]])

        #expect(values.count == 1)
        #expect(values.first?["identifier"] as? String == "large_text_enabled")
        #expect(values.first?["value"] as? Bool == true)
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
}
