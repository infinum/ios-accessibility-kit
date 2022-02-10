//
//  AccessibilityObserver.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

protocol Observer: AnyObject {}

protocol AccessibilityObserver: Observer {
    func accessibilityStateDidChange(_ accessibilityState: AccessibilityState)
}
