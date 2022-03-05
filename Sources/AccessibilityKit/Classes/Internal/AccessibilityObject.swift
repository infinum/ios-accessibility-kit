//
//  AccessibilityObject.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 01.03.2022..
//

import Foundation

protocol AccessibilityObject {

    var type: AccessibilityType { get }
    var name: String { get}
    var notificationName: Notification.Name { get }

    func state(customIdentifier: String?) -> AccessibilityState
}
