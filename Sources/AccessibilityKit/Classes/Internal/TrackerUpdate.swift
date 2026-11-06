//
//  TrackerUpdate.swift
//  AccessibilityKit
//

import Foundation

///
/// A weakly held listener the tracker tells about every delivery — the
/// kit — without touching the completion the app registered through
/// ``AccessibilityKit/observeAccessibilityTracking(completion:)``.
///
@MainActor
protocol TrackerListener: AnyObject {
    func trackerDidUpdate(_ update: TrackerUpdate)
}

///
/// What the tracker tells the kit on each delivery: everything a screen
/// needs to show the tracked features, worked out when the snapshot was
/// taken, so a row's value, its change mark and its history agree.
///
struct TrackerUpdate: Sendable {

    /// Why the update was delivered.
    enum Reason: Equatable, Sendable {
        /// The listener's first update, taken when it registered.
        case registration
        /// Tracking was configured again.
        case reconfiguration
        /// A tracked feature changed.
        case change
    }

    /// The snapshot the app's observations are handed, transforms applied.
    let snapshot: AccessibilitySnapshot
    ///
    /// Each tracked feature's displayed history, oldest first, keyed by
    /// identifier: its recorded values through its transform, with changes
    /// the transform folds together merged.
    ///
    let histories: [String: [AccessibilityHistoryEntry]]
    let status: TrackingStatus
    let reason: Reason
}

///
/// What the kit says about tracking.
///
enum TrackingStatus: Equatable, Sendable {
    /// Tracking is not configured, or tracks nothing.
    case notTracked
    /// Tracking follows changes as they happen.
    case live
    /// Tracking read the settings once, at this time.
    case snapshot(Date)
}
