//
//  Encodable+Dictionary.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 04.04.2022..
//

import Foundation

public extension Encodable {

    ///
    /// Encodes the value to JSON and returns it as a dictionary.
    ///
    /// Intended for converting an ``AccessibilitySnapshot`` before sending it
    /// onward:
    ///
    /// ```swift
    /// let payload = snapshot.toDictionary()
    /// ```
    ///
    /// - Returns: The encoded value as a dictionary, or `nil` if it cannot be
    ///   encoded or does not encode to a JSON object.
    ///
    func toDictionary() -> [String: Any]? {
        guard
            let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else { return nil }
        return dictionary
    }
}
