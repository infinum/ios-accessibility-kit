//
//  AccessibilitySnapshotTests.swift
//  AccessibilityKitTests
//

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
}
