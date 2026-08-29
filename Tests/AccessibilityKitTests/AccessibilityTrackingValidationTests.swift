//
//  AccessibilityTrackingValidationTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@MainActor
@Suite("Tracking validation")
struct AccessibilityTrackingValidationTests {

    @Test("Accepts a configuration tracking each type once")
    func acceptsUniqueTypes() throws {
        let configuration = try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [
                AccessibilityTrackingObject(type: .voiceOver),
                AccessibilityTrackingObject(type: .boldText)
            ]
        )

        #expect(configuration.objects.count == 2)
    }

    @Test("Rejects a configuration tracking the same type twice")
    func rejectsDuplicateTypesInConfiguration() {
        #expect(throws: AccessibilityTrackingError.duplicateType(.voiceOver)) {
            try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .voiceOver),
                    AccessibilityTrackingObject(type: .voiceOver, customIdentifier: "other")
                ]
            )
        }
    }

    @Test("Rejects a snapshot request tracking the same type twice")
    func rejectsDuplicateTypesInSnapshotRequest() {
        let kit = AccessibilityKit(
            monitor: AccessibilityMonitor(notificationCenter: NotificationCenter())
        )

        #expect(throws: AccessibilityTrackingError.duplicateType(.fontScale)) {
            try kit.currentAccessibilitySnapshot(
                for: [
                    AccessibilityTrackingObject(type: .fontScale),
                    AccessibilityTrackingObject(type: .fontScale, customIdentifier: "scale")
                ]
            )
        }
    }

    @Test("Reads a snapshot when each type appears once")
    func readsSnapshotForUniqueTypes() throws {
        let kit = AccessibilityKit(
            monitor: AccessibilityMonitor(notificationCenter: NotificationCenter())
        )

        let snapshot = try kit.currentAccessibilitySnapshot(
            for: [AccessibilityTrackingObject(type: .voiceOver)]
        )

        #expect(snapshot.states.count == 1)
    }
}
