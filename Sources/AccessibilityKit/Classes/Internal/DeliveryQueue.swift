//
//  DeliveryQueue.swift
//  AccessibilityKit
//

import Foundation

///
/// Where the tracker runs work on a later main-queue turn: snapshot
/// deliveries, and the check that an observation was kept.
///
/// Work never runs inside the call that schedules it, so a completion that
/// reconfigures tracking, or registers or ends an observation, does so
/// between deliveries rather than in the middle of one. Work runs in the
/// order it was scheduled.
///
@MainActor
protocol DeliveryQueue {

    func schedule(_ work: @escaping @MainActor @Sendable () -> Void)
}

///
/// The main queue: each piece of work runs on a later turn of the main run
/// loop. The tracker uses this outside tests.
///
struct MainDeliveryQueue: DeliveryQueue {

    func schedule(_ work: @escaping @MainActor @Sendable () -> Void) {
        DispatchQueue.main.async(execute: work)
    }
}
