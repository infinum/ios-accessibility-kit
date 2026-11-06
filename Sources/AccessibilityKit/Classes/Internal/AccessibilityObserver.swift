//
//  AccessibilityObserver.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

@MainActor
protocol Observer: AnyObject {}

@MainActor
protocol AccessibilityObserver: Observer {
    func accessibilityStateDidChange(_ state: AccessibilityState)
}
