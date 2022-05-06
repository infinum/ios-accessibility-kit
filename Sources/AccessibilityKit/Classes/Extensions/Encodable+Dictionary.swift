//
//  Encodable+Dictionary.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 04.04.2022..
//

import Foundation

public extension Encodable {

    func toDictionary() -> [String: Any]? {
        guard
            let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else { return nil }
        return dictionary
    }
}
