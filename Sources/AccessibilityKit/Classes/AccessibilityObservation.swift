//
//  AccessibilityObservation.swift
//  AccessibilityKit
//

import Foundation
import os

///
/// An observation registered with
/// ``AccessibilityKit/observeAccessibilityTracking(completion:)``.
///
/// Keep it for as long as you want snapshots. The observation ends when you
/// call ``cancel()`` or when this object is released, whichever comes first.
/// Once it has ended on the main actor, its completion is never called
/// again, not even for a snapshot already in flight. Released on another
/// thread, it ends before the next delivery begins; one already running on
/// the main actor finishes first.
///
/// The library holds the completion until the observation ends. A
/// completion that strongly captures the object holding its observation
/// keeps both alive for good, so capture that owner weakly.
///
/// In debug builds, an observation released in the same main-queue turn it
/// was created in, without being cancelled, logs a warning: the usual cause
/// is a result that was never stored.
///
/// ```swift
/// final class SettingsReporter {
///
///     private var observation: AccessibilityObservation?
///
///     func start() {
///         observation = AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
///             // handle the snapshot
///         }
///     }
/// }
/// ```
///
public final class AccessibilityObservation: Sendable {

    // MARK: - Internal properties

    /// Shared with the monitor, which checks it before every delivery.
    let state = ObservationState()

    // MARK: - Private properties

    private let cancellation: @MainActor @Sendable () -> Void

    // MARK: - Lifecycle

    init(cancellation: @escaping @MainActor @Sendable () -> Void) {
        self.cancellation = cancellation
    }

    deinit {
        #if DEBUG
        // Checked before marking it ended: a cancelled observation was ended
        // on purpose, and one that outlived its first turn was kept.
        if !state.isCancelled, !state.wasKept {
            Logger(subsystem: "com.infinum.AccessibilityKit", category: "Tracking").warning(
                "An accessibility observation was released right after it was created, so it receives no snapshots. If that was not intended, keep the AccessibilityObservation that observeAccessibilityTracking(completion:) returns for as long as you want them."
            )
        }
        #endif

        // Marked at once, on whatever thread releases it, so a delivery
        // already queued on the main queue finds it ended.
        state.cancel()

        let cancellation = self.cancellation
        guard Thread.isMainThread else {
            Task { @MainActor in cancellation() }
            return
        }
        MainActor.assumeIsolated { cancellation() }
    }

    // MARK: - Public methods

    ///
    /// Ends the observation. Its completion is not called again. Calling
    /// this more than once has no further effect.
    ///
    @MainActor
    public func cancel() {
        state.cancel()
        cancellation()
    }
}

///
/// Whether an observation has ended, readable and settable from any thread.
///
final class ObservationState: @unchecked Sendable {

    // Never held while app code runs, so a release on another thread can
    // never wait on a completion, nor a completion on that thread.
    private let lock = NSLock()
    private var cancelled = false
    private var kept = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    /// Whether the observation outlived the main-queue turn it was created in.
    var wasKept: Bool {
        lock.lock()
        defer { lock.unlock() }
        return kept
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    func markKept() {
        lock.lock()
        kept = true
        lock.unlock()
    }
}
