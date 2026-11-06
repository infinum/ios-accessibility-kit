//
//  AccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 01.03.2022..
//

import Foundation

@MainActor
protocol AccessibilityObject {

    var type: AccessibilityType { get }
    var notificationName: Notification.Name { get }

    func state(customIdentifier: String?) -> AccessibilityState
}

extension AccessibilityObject {

    /// The feature's display name, from the one table ``AccessibilityType`` keeps.
    var name: String {
        return type.displayName
    }
}
