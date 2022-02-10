//
//  AccessibilityState.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

public protocol AccessibilityState {
    var type: AccessibilityType { get }
    var identifier: String { get }
    var name: String { get }
    var enabled: Bool { get }
}

extension AccessibilityState {

    public var identifier: String { type.rawValue }

    public var name: String { AccessibilityName.name(for: type) }
}
