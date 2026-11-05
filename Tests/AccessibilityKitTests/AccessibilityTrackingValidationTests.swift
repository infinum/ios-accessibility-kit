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

    @Test("Accepts one type tracked twice under two identifiers")
    func acceptsOneTypeUnderTwoIdentifiers() throws {
        let configuration = try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [
                AccessibilityTrackingObject(type: .fontScale),
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { .flag(($0.scaleValue ?? 1) >= 1.2) }
                )
            ]
        )

        #expect(configuration.objects.count == 2)
    }

    ///
    /// Without a custom identifier both objects fall back to the type's
    /// default one, which is the collision the validation exists to catch.
    ///
    @Test("Rejects one type tracked twice under its default identifier")
    func rejectsOneTypeUnderItsDefaultIdentifierTwice() {
        #expect(throws: AccessibilityTrackingError.duplicateIdentifier("voice_over")) {
            try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .voiceOver),
                    AccessibilityTrackingObject(type: .voiceOver)
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

    @Test("Reads one type raw and corrected under two identifiers")
    func readsOneTypeRawAndCorrected() throws {
        let kit = AccessibilityKit(
            monitor: AccessibilityMonitor(notificationCenter: NotificationCenter())
        )

        let snapshot = try kit.currentAccessibilitySnapshot(
            for: [
                AccessibilityTrackingObject(type: .fontScale),
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { _ in .flag(true) }
                )
            ]
        )

        // Checked before the lookup below, which keeps the first of two
        // states sharing an identifier rather than trapping on them.
        #expect(snapshot.states.map(\.identifier) == ["font_scale", "large_text_enabled"])

        let values = Dictionary(
            snapshot.states.map { ($0.identifier, $0.value) },
            uniquingKeysWith: { first, _ in first }
        )
        #expect(values["font_scale"]?.scaleValue != nil)
        #expect(values["large_text_enabled"] == .flag(true))
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
