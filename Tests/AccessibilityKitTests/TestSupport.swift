//
//  TestSupport.swift
//  AccessibilityKitTests
//

import Foundation

///
/// Polls until the expectation holds, so a positive assertion never depends on
/// a fixed delay being long enough, and a broken emission fails the test at
/// the timeout instead of hanging the suite.
///
@MainActor
func poll(until condition: () -> Bool, timeout: TimeInterval = 2) async {
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
