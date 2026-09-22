//
//  AccessibilityKit.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

import UIKit
import SwiftUI

///
/// Reads and tracks the accessibility features the user has enabled.
///
/// ## Overview
///
/// Use ``shared``. There are two ways to read accessibility state.
///
/// For a one-off reading, call ``currentAccessibilitySnapshot(for:)``; no
/// setup is needed:
///
/// ```swift
/// let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
///     for: [AccessibilityTrackingObject(type: .voiceOver)]
/// )
/// ```
///
/// To follow changes for the life of the app, configure tracking once — in
/// `application(_:didFinishLaunchingWithOptions:)`, say — and then observe:
///
/// ```swift
/// let configuration = try AccessibilityTrackingConfiguration(
///     fetchType: .continuous,
///     objects: [AccessibilityTrackingObject(type: .voiceOver)]
/// )
///
/// AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
///
/// AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
///     // handle the snapshot
/// }
/// ```
///
@MainActor
public final class AccessibilityKit {

    // MARK: - Public properties

    /// The shared instance.
    public static let shared = AccessibilityKit()

    // MARK: - Private properties

    private let monitor: AccessibilityMonitor

    // MARK: - Lifecycle

    init(monitor: AccessibilityMonitor = .shared) {
        self.monitor = monitor
    }

    // MARK: - Public methods

    ///
    /// Reads the current state of the given accessibility features.
    ///
    /// Tracking does not need to be configured to call this.
    ///
    /// - Parameter objects: The features to read. Each ``AccessibilityType``
    ///   must appear at most once.
    /// - Returns: A snapshot of those features, as they are right now.
    /// - Throws: ``AccessibilityTrackingError/duplicateType(_:)`` if a feature
    ///   is supplied more than once, or
    ///   ``AccessibilityTrackingError/duplicateIdentifier(_:)`` if two
    ///   features are supplied under the same identifier.
    ///
    public func currentAccessibilitySnapshot(for objects: [AccessibilityTrackingObject]) throws -> AccessibilitySnapshot {
        try objects.validateUniqueTracking()

        return monitor.currentAccessibilitySnapshot(for: objects)
    }

    ///
    /// Configures which accessibility features are tracked, and how often.
    ///
    /// Call this before ``observeAccessibilityTracking(completion:)``.
    /// Calling it again replaces the previous configuration. An observation
    /// already registered stays registered, but reconfiguring does not emit
    /// a snapshot of its own: the next one arrives at the next change, and
    /// only if the new configuration is
    /// ``AccessibilityFetchType/continuous``.
    ///
    /// - Parameter configuration: The features to track and the fetch type.
    ///
    public func configureAccessibilityTracking(with configuration: AccessibilityTrackingConfiguration) {
        monitor.configureAccessibilityTracking(with: configuration)
    }

    ///
    /// Observes the accessibility features that tracking was configured with.
    ///
    /// The first snapshot is delivered asynchronously, on the main queue, as
    /// soon as observation begins. Whether more follow depends on the
    /// configured ``AccessibilityFetchType``:
    /// ``AccessibilityFetchType/initial`` reports only that first snapshot,
    /// ``AccessibilityFetchType/continuous`` reports again on every change.
    ///
    /// Only one observation is active at a time — calling this again replaces
    /// the previous completion. A snapshot already in flight still reaches
    /// the completion that was registered when it was taken, so a replacement
    /// never receives someone else's first snapshot. Snapshots are delivered
    /// on the main queue.
    ///
    /// - Parameter completion: Called with each snapshot. Nothing is
    ///   delivered if tracking has not been configured.
    ///
    public func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) {
        monitor.observeAccessibilityTracking(completion: completion)
    }

    ///
    /// Presents the accessibility monitor, a screen listing the tracked
    /// features and their current values.
    ///
    /// Requires tracking to have been configured — the monitor shows the
    /// features from that configuration, with any transforms applied, so it
    /// shows exactly what the app reports.
    ///
    /// The monitor observes on its own, so presenting it does not replace a
    /// completion registered through
    /// ``observeAccessibilityTracking(completion:)``.
    ///
    /// - Parameter viewController: The view controller to present from.
    ///
    public func presentAccessibilityMonitor(on viewController: UIViewController) {
        let monitorViewController = UIHostingController(rootView: AccessibilityMonitorView(onDismiss: { viewController.dismiss(animated: true) }))

        viewController.present(
            monitorViewController,
            animated: true,
            completion: nil
        )
    }
}
