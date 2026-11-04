//
//  AccessibilityTrackingConfiguration.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 23.02.2022..
//

import Foundation

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
/// Every tracking object needs an identifier of its own: identifiers key
/// both the encoded output and the rows of the accessibility monitor. Give
/// an object a `customIdentifier` when its transform changes the kind of
/// value, and when the same ``AccessibilityType`` is tracked more than once —
/// raw and corrected, say.
///
public struct AccessibilityTrackingObject {

    // MARK: - Internal properties

    let customIdentifier: String?
    let type: AccessibilityType
    let transform: (@Sendable (AccessibilityValue) -> AccessibilityValue)?

    // MARK: - Lifecycle

    ///
    /// Creates a tracking object for one accessibility feature.
    ///
    /// - Parameters:
    ///   - type: The feature to track.
    ///   - customIdentifier: The identifier to report the feature under.
    ///     Defaults to the type's raw value.
    ///   - transform: A correction applied to the value in every snapshot
    ///     this object produces, and so in their encoded output. Passed to
    ///     ``AccessibilityKit/currentAccessibilitySnapshot(for:)``, it
    ///     corrects only that snapshot; to correct observed changes and the
    ///     accessibility monitor too, include the object in the configuration
    ///     passed to ``AccessibilityKit/configureAccessibilityTracking(with:)``.
    ///     Defaults to `nil`, which reports the value the system gives.
    ///
    public init (
        type: AccessibilityType,
        customIdentifier: String? = nil,
        transform: (@Sendable (AccessibilityValue) -> AccessibilityValue)? = nil
    ) {
        self.type = type
        self.customIdentifier = customIdentifier
        self.transform = transform
    }
}

///
/// How often tracking should report.
///
public enum AccessibilityFetchType {

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
/// AccessibilityKit.shared.configureAccessibilityTracking(
///     with: AccessibilityTrackingConfiguration(
///         fetchType: .continuous,
///         objects: [
///             AccessibilityTrackingObject(type: .boldText),
///             AccessibilityTrackingObject(type: .voiceOver)
///         ]
///     )
/// )
/// ```
///
public struct AccessibilityTrackingConfiguration {

    // MARK: - Internal properties

    let fetchType: AccessibilityFetchType
    let objects: [AccessibilityTrackingObject]

    ///
    /// Creates a tracking configuration.
    ///
    /// - Parameters:
    ///   - fetchType: Whether to report once or on every change.
    ///   - objects: The features to track, each under an identifier of its
    ///     own.
    ///
    public init(fetchType: AccessibilityFetchType, objects: [AccessibilityTrackingObject]) {
        self.fetchType = fetchType
        self.objects = objects
    }
}
