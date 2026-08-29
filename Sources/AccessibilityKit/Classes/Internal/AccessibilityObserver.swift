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

///
/// A weakly held listener that receives whole snapshots — the accessibility
/// monitor UI — without touching the completion the app registered through
/// ``AccessibilityKit/observeAccessibilityTracking(completion:)``.
///
@MainActor
protocol AccessibilitySnapshotObserver: AnyObject {
    func accessibilitySnapshotDidChange(_ snapshot: AccessibilitySnapshot)
}
