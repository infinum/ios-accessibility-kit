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

    @Test("Rejects two features reported under the same identifier")
    func rejectsDuplicateIdentifiers() {
        #expect(throws: AccessibilityTrackingError.duplicateIdentifier("enabled")) {
            try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .voiceOver, customIdentifier: "enabled"),
                    AccessibilityTrackingObject(type: .boldText, customIdentifier: "enabled")
                ]
            )
        }
    }

    ///
    /// A custom identifier can collide with another feature's default one,
    /// which is the same collision spelled differently.
    ///
    @Test("Rejects a custom identifier that is another feature's default")
    func rejectsCustomIdentifierMatchingAnotherDefault() {
        #expect(throws: AccessibilityTrackingError.duplicateIdentifier("bold_text")) {
            try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .boldText),
                    AccessibilityTrackingObject(type: .voiceOver, customIdentifier: "bold_text")
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

    @Test("Rejects a snapshot request sharing one identifier between features")
    func rejectsDuplicateIdentifiersInSnapshotRequest() {
        let kit = AccessibilityKit(
            monitor: AccessibilityMonitor(notificationCenter: NotificationCenter())
        )

        #expect(throws: AccessibilityTrackingError.duplicateIdentifier("enabled")) {
            try kit.currentAccessibilitySnapshot(
                for: [
                    AccessibilityTrackingObject(type: .fontScale, customIdentifier: "enabled"),
                    AccessibilityTrackingObject(type: .voiceOver, customIdentifier: "enabled")
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
