//
//  TestSupport.swift
//  AccessibilityKitTests
//

import Foundation

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

    while !condition() && Date() < deadline {
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
}

///
/// A fixed wait, used only where the assertion is that nothing *further*
/// happens — absence cannot be established by polling.
///
func settle() async {
    try? await Task.sleep(nanoseconds: 200_000_000)
}

///
/// Counts deliveries on the main queue, where the monitor delivers.
///
@MainActor
final class EmissionCounter {

    private(set) var count = 0

    func increment() {
        count += 1
    }
}
