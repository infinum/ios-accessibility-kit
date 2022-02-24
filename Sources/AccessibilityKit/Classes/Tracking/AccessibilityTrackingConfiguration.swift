//
//  AccessibilityTrackingConfiguration.swift
//  
//
//  Created by Nikola Majcen on 23.02.2022..
//

import Foundation

public struct AccessibilityTrackingObject {
    let customIdentifier: String?
    let type: AccessibilityType
}

public enum AccessibilityFetchType {
    case initial
    case continuous
}

public struct AccessibilityTrackingConfiguration {

    // MARK: - Public properties

    let fetchType: AccessibilityFetchType
    let objects: [AccessibilityTrackingObject]
}
