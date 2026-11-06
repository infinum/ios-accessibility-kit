//
//  AccessibilitySnapshot.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

///
/// The state of every tracked accessibility feature, each read in turn when
/// the snapshot is taken.
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
    /// The states of the tracked features, sorted by accessibility type, and
    /// by identifier among states of the same type.
    ///
    public let states: [AccessibilityState]

    ///
    /// When the snapshot was taken.
    ///
    /// It is not part of the encoded output, which carries only the values.
    ///
    public let date: Date

    ///
    /// Creates a snapshot from states that have already been produced.
    ///
    /// Use this to re-wrap states adjusted with
    /// ``AccessibilityState/withValue(_:)`` so they can be encoded and sent on
    /// like any other snapshot.
    ///
    /// Unlike the tracking paths, this does not check the states it is given:
    /// a snapshot built from two others can carry one identifier twice. Keep
    /// identifiers unique — an identifier is what a consumer tells entries
    /// apart by, and what the accessibility monitor keys its rows on.
    ///
    /// - Parameters:
    ///   - states: The states to carry. They come out ordered by
    ///     accessibility type, and by identifier among states of the same
    ///     type, whatever order they are supplied in.
    ///   - date: When the states were read. Defaults to now.
    ///
    public init(states: [AccessibilityState], date: Date = Date()) {
        self.date = date
        // The identifier breaks ties here rather than in `<`: `==` ignores
        // the identifier, so a `<` ordered by it would call two equal states
        // unequal.
        self.states = states.sorted { lhs, rhs in
            lhs < rhs || (!(rhs < lhs) && lhs.identifier < rhs.identifier)
        }
    }

    @MainActor
    init(
        trackingObjects: [AccessibilityTrackingObject],
        readState: AccessibilityStateReader = AccessibilityObjectFactory.readState
    ) {
        self.init(
            states: trackingObjects.map { trackingObject in
                let raw = readState(trackingObject.type)
                let state = AccessibilityState(
                    type: raw.type,
                    name: raw.name,
                    value: raw.value,
                    customIdentifier: trackingObject.customIdentifier
                )

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
