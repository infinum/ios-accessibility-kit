//
//  AccessibilitySnapshot.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

///
/// The state of every tracked accessibility feature, read at one moment.
///
/// ## Overview
///
/// Snapshots come from ``AccessibilityKit/currentAccessibilitySnapshot(for:)``
/// or from ``AccessibilityKit/observeAccessibilityTracking(completion:)``.
///
/// A snapshot is `Encodable`, and ``toDictionary()`` converts it for sending
/// onward. The encoded form is a `values` array of `identifier` / `value`
/// pairs:
///
/// ```json
/// {
///     "values": [
///         { "identifier": "bold_text", "value": true },
///         { "identifier": "font_scale", "value": 1.2352941176470589 }
///     ]
/// }
/// ```
///
public struct AccessibilitySnapshot: Sendable {

    ///
    /// The states of the tracked features, sorted by accessibility type.
    ///
    public let states: [AccessibilityState]

    ///
    /// Creates a snapshot from states that have already been produced.
    ///
    /// Use this to re-wrap states adjusted with
    /// ``AccessibilityState/withValue(_:)`` so they can be encoded and sent on
    /// like any other snapshot.
    ///
    /// Unlike the tracking paths, this does not check the states it is given:
    /// a snapshot built from two others can carry one feature, or one
    /// identifier, twice. Keep them unique — an identifier is what a consumer
    /// tells entries apart by, and what the accessibility monitor keys its
    /// rows on.
    ///
    /// - Parameter states: The states to carry. They come out ordered by
    ///   accessibility type whatever order they are supplied in.
    ///
    public init(states: [AccessibilityState]) {
        self.states = states.sorted()
    }

    @MainActor
    init(trackingObjects: [AccessibilityTrackingObject]) {
        self.init(
            states: trackingObjects.map { trackingObject in
                let state = AccessibilityObjectFactory
                    .object(for: trackingObject.type)
                    .state(customIdentifier: trackingObject.customIdentifier)

                guard let transform = trackingObject.transform else { return state }
                return state.withValue(transform(state.value))
            }
        )
    }
}

extension AccessibilitySnapshot: Encodable {

    enum CodingKeys: String, CodingKey {
        case states = "values"
    }
}
