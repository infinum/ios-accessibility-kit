//
//  AccessibilityTrackingConfiguration.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 23.02.2022..
//

import Foundation

///
/// An error raised while setting up accessibility tracking.
///
public enum AccessibilityTrackingError: Error, Equatable {

    ///
    /// The same accessibility feature was supplied more than once.
    ///
    /// A feature has a single identifier, so tracking it twice would report it
    /// twice — once under each identifier — rather than reporting it once.
    ///
    case duplicateType(AccessibilityType)
}

///
/// One accessibility feature to track, and how to report it.
///
/// ## Overview
///
/// Track a feature under its default identifier, under one of your own, or
/// with the reported value corrected at the point it is produced:
///
/// ```swift
/// AccessibilityTrackingObject(type: .voiceOver)
///
/// AccessibilityTrackingObject(type: .boldText, customIdentifier: "bold")
///
/// AccessibilityTrackingObject(
///     type: .fontScale,
///     customIdentifier: "large_text_enabled",
///     transform: { value in .flag((value.scaleValue ?? 1) >= 1.2) }
/// )
/// ```
///
/// Track each ``AccessibilityType`` at most once. A feature has a single
/// identifier, so supplying the same type twice is rejected:
/// ``AccessibilityTrackingConfiguration/init(fetchType:objects:)`` and
/// ``AccessibilityKit/currentAccessibilitySnapshot(for:)`` throw
/// ``AccessibilityTrackingError/duplicateType(_:)``.
///
public struct AccessibilityTrackingObject: Sendable {

    // MARK: - Internal properties

    let customIdentifier: String?
    let type: AccessibilityType
    let transform: (@MainActor @Sendable (AccessibilityValue) -> AccessibilityValue)?

    // MARK: - Lifecycle

    ///
    /// Creates a tracking object for one accessibility feature.
    ///
    /// - Parameters:
    ///   - type: The feature to track.
    ///   - customIdentifier: The identifier to report the feature under.
    ///     Defaults to the type's raw value.
    ///   - transform: A correction applied to the value wherever this feature
    ///     is produced — direct snapshots, observed changes, the encoded
    ///     output and the accessibility monitor. Defaults to `nil`, which
    ///     reports the value the system gives. Runs on the main actor, where
    ///     accessibility state is read, so it may touch main-actor state.
    ///
    public init (
        type: AccessibilityType,
        customIdentifier: String? = nil,
        transform: (@MainActor @Sendable (AccessibilityValue) -> AccessibilityValue)? = nil
    ) {
        self.type = type
        self.customIdentifier = customIdentifier
        self.transform = transform
    }
}

///
/// How often tracking should report.
///
public enum AccessibilityFetchType: Sendable {

    /// Report once, when observation begins.
    case initial

    /// Report when observation begins, and again on every change.
    case continuous
}

///
/// What to track, and how often.
///
/// ## Overview
///
/// Pass a configuration to
/// ``AccessibilityKit/configureAccessibilityTracking(with:)``, then observe
/// with ``AccessibilityKit/observeAccessibilityTracking(completion:)``:
///
/// ```swift
/// let configuration = try AccessibilityTrackingConfiguration(
///     fetchType: .continuous,
///     objects: [
///         AccessibilityTrackingObject(type: .boldText),
///         AccessibilityTrackingObject(type: .voiceOver)
///     ]
/// )
///
/// AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
/// ```
///
public struct AccessibilityTrackingConfiguration: Sendable {

    // MARK: - Internal properties

    let fetchType: AccessibilityFetchType
    let objects: [AccessibilityTrackingObject]

    ///
    /// Creates a tracking configuration.
    ///
    /// - Parameters:
    ///   - fetchType: Whether to report once or on every change.
    ///   - objects: The features to track. Each ``AccessibilityType`` must
    ///     appear at most once.
    /// - Throws: ``AccessibilityTrackingError/duplicateType(_:)`` if a feature
    ///   is supplied more than once.
    ///
    public init(fetchType: AccessibilityFetchType, objects: [AccessibilityTrackingObject]) throws {
        try objects.validateUniqueTypes()

        self.fetchType = fetchType
        self.objects = objects
    }
}

// MARK: - Validation

extension Array where Element == AccessibilityTrackingObject {

    ///
    /// Checks that no accessibility feature is tracked more than once.
    ///
    func validateUniqueTypes() throws {
        var seen = Set<AccessibilityType>()

        for object in self where seen.insert(object.type).inserted == false {
            throw AccessibilityTrackingError.duplicateType(object.type)
        }
    }
}
