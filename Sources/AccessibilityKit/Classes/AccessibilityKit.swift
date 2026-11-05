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
/// do {
///     let configuration = try AccessibilityTrackingConfiguration(
///         fetchType: .continuous,
///         objects: [AccessibilityTrackingObject(type: .voiceOver)]
///     )
///     AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
/// } catch {
///     assertionFailure("Invalid accessibility tracking configuration: \(error)")
/// }
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
    /// - Parameter objects: The features to read, each under an identifier
    ///   of its own.
    /// - Returns: A snapshot of those features, as they are right now.
    /// - Throws: ``AccessibilityTrackingError/duplicateIdentifier(_:)`` if
    ///   two objects are supplied under the same identifier.
    ///
    public func currentAccessibilitySnapshot(for objects: [AccessibilityTrackingObject]) throws -> AccessibilitySnapshot {
        try objects.validateUniqueIdentifiers()

        return monitor.currentAccessibilitySnapshot(for: objects)
    }

    ///
    /// Configures which accessibility features are tracked, and how often.
    ///
    /// Call this before ``observeAccessibilityTracking(completion:)``.
    /// Calling it again replaces the previous configuration. An observation
    /// already registered stays registered, but reconfiguring does not emit
    /// a snapshot of its own to it: the next one arrives at the next change,
    /// and only if the new configuration is
    /// ``AccessibilityFetchType/continuous``. A snapshot taken under the
    /// previous configuration and not yet delivered, the first one
    /// included, is dropped.
    ///
    /// - Parameter configuration: The features to track and the fetch type.
    ///
    public func configureAccessibilityTracking(with configuration: AccessibilityTrackingConfiguration) {
        monitor.configureAccessibilityTracking(with: configuration)
    }

    ///
    /// Observes the accessibility features that tracking was configured with.
    ///
    /// Snapshots are delivered asynchronously, on the main queue. The first
    /// is delivered as soon as observation begins. Whether more follow
    /// depends on the configured ``AccessibilityFetchType``:
    /// ``AccessibilityFetchType/initial`` reports only that first snapshot,
    /// ``AccessibilityFetchType/continuous`` reports again on every change.
    ///
    /// Only one observation is active at a time — calling this again replaces
    /// the previous completion, which is not called again, not even for a
    /// snapshot already in flight. The replacement receives only snapshots
    /// taken after it was registered, starting with its own first one. Until
    /// it is replaced, the completion is kept, and reconfiguring tracking does
    /// not clear it, so capture its owner weakly.
    ///
    /// - Parameter completion: Called with each snapshot. If tracking has
    ///   not been configured yet, no first snapshot is delivered; the
    ///   completion is still kept, and receives changes once a
    ///   ``AccessibilityFetchType/continuous`` configuration is in place.
    ///
    public func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) {
        monitor.observeAccessibilityTracking(completion: completion)
    }

    ///
    /// Presents the accessibility monitor, a screen listing the tracked
    /// features and their values.
    ///
    /// The list updates as settings change only when tracking is configured
    /// with ``AccessibilityFetchType/continuous``; under
    /// ``AccessibilityFetchType/initial`` it shows the values from when it
    /// was presented. Reconfiguring tracking refreshes it with the newly
    /// configured features.
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
