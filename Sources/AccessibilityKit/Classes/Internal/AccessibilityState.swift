//
//  AccessibilityState.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation
import UIKit

public enum AccessibilityValue {
    case flag(Bool)
    case number(Double)
}

public struct AccessibilityState {

    // MARK: - Public methods

    let type: AccessibilityType
    let name: String
    let value: AccessibilityValue
    let identifier: String

    // MARK: - Lifecycle

    init(
        type: AccessibilityType,
        name: String,
        value: AccessibilityValue,
        customIdentifier: String? = nil
    ) {
        self.type = type
        self.name = name
        self.value = value
        self.identifier = customIdentifier ?? type.rawValue
    }
}

extension AccessibilityState: Equatable {
    
    public static func == (lhs: AccessibilityState, rhs: AccessibilityState) -> Bool {
        return lhs.type == rhs.type
    }
}


extension AccessibilityState: Comparable {

    public static func < (lhs: AccessibilityState, rhs: AccessibilityState) -> Bool {
        return lhs.type.rawValue < rhs.type.rawValue
    }
}
