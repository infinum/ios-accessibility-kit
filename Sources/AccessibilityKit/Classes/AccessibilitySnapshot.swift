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
/// ## Discussion
///
/// Snapshots come from ``AccessibilityKit/currentAccessibilitySnapshot(for:)``
/// or from ``AccessibilityKit/observeAccessibilityTracking(completion:)``.
///
/// A snapshot is `Encodable`, and ``Swift/Encodable/toDictionary()`` converts
/// it for sending onward. The encoded form is a `values` array of
/// `identifier` / `value` pairs:
///
/// ```json
/// {
///     "values": [
///         { "identifier": "bold_text", "value": true },
///         { "identifier": "font_scale", "value": 1.25 }
///     ]
/// }
/// ```
///
public struct AccessibilitySnapshot {

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
    /// - Parameter states: The states to carry. They are sorted on the way in,
    ///   so the order they are supplied in does not matter.
    ///
    public init(states: [AccessibilityState]) {
        self.states = states.sorted()
    }

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
