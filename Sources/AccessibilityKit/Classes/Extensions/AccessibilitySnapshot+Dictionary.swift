//
//  AccessibilitySnapshot+Dictionary.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 04.04.2022..
//

import Foundation

///
/// An error raised while converting a snapshot to a dictionary.
///
public enum AccessibilityEncodingError: Error, Equatable {

    /// The snapshot encoded to JSON, but not to a JSON object.
    case notAJSONObject
}

public extension AccessibilitySnapshot {

    ///
    /// Encodes the snapshot to JSON and returns it as a dictionary, ready to
    /// send onward.
    ///
    /// ```swift
    /// let payload = try snapshot.toDictionary()
    /// ```
    ///
    /// - Returns: The snapshot as a dictionary, with a `values` array of
    ///   `identifier` / `value` pairs.
    /// - Throws: Whatever `JSONEncoder` or `JSONSerialization` throws, or
    ///   ``AccessibilityEncodingError/notAJSONObject`` if the encoded form is
    ///   not a JSON object.
    ///
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        guard let dictionary = json as? [String: Any] else {
            throw AccessibilityEncodingError.notAJSONObject
        }
        return dictionary
    }
}
