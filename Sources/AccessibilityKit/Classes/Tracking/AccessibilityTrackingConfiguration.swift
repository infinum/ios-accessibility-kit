//
//  AccessibilityTrackingConfiguration.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 23.02.2022..
//

import Foundation

public struct AccessibilityTrackingObject {

    //  MARK: - Public properties

    let customIdentifier: String?
    let type: AccessibilityType

    // MARK: - Lifecycle

    public init (type: AccessibilityType, customIdentifier: String? = nil) {
        self.type = type
        self.customIdentifier = customIdentifier
    }
}

public enum AccessibilityFetchType {
    case initial
    case continuous
}

public struct AccessibilityTrackingConfiguration {

    // MARK: - Public properties

    let fetchType: AccessibilityFetchType
    let objects: [AccessibilityTrackingObject]

    public init(fetchType: AccessibilityFetchType, objects: [AccessibilityTrackingObject]) {
        self.fetchType = fetchType
        self.objects = objects
    }
}
