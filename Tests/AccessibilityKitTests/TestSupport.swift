//
//  TestSupport.swift
//  AccessibilityKitTests
//

import Foundation
@testable import AccessibilityKit

///
/// Polls until the expectation holds, so a positive assertion never depends on
/// a fixed delay being long enough. It returns when the condition holds or the
/// timeout passes, whichever comes first, and asserts nothing itself - the
/// caller states the expectation afterwards, so a missing emission fails there
/// rather than hanging the suite.
///
/// The timeout is generous because a cold simulator has been seen to take
/// longer than two seconds to deliver.
///
@MainActor
func poll(until condition: () -> Bool, timeout: TimeInterval = 5) async {
    let deadline = Date().addingTimeInterval(timeout)

    while !condition() && Date() < deadline && !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
}

///
/// A fixed wait, used only where the assertion is that nothing *further*
/// happens — absence cannot be established by polling.
///
@MainActor
func settle() async {
    try? await Task.sleep(nanoseconds: 200_000_000)
}

///
/// Counts deliveries on the main queue, where the monitor delivers.
///
@MainActor
final class EmissionCounter {

    private(set) var count = 0
    /// The features each recorded snapshot reported, in delivery order.
    private(set) var emittedTypes = [[AccessibilityType]]()
    /// The identifiers the most recently recorded snapshot reported.
    private(set) var lastIdentifiers = [String]()

    func increment() {
        count += 1
    }

    func record(_ snapshot: AccessibilitySnapshot) {
        emittedTypes.append(snapshot.states.map(\.type))
        lastIdentifiers = snapshot.states.map(\.identifier)
        increment()
    }
}

///
/// Stands in for the system's accessibility settings, so a test can change
/// one and post its notification. Every feature reads off unless set, and
/// font scale reads as the default size.
///
@MainActor
final class SystemValues {

    var values = [AccessibilityType: AccessibilityValue]()

    /// Holds this object strongly: a monitor may outlive the test's reference.
    var read: AccessibilityStateReader {
        return { type in
            let value = self.values[type] ?? (type == .fontScale ? .scale(1) : .flag(false))
            return AccessibilityState(type: type, name: type.displayName, value: value)
        }
    }
}
