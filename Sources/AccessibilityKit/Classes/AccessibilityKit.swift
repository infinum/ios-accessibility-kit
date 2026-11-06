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
/// `application(_:didFinishLaunchingWithOptions:)`, say — and then observe,
/// keeping the observation for as long as you want snapshots:
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
/// observation = AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
///     // handle the snapshot
/// }
/// ```
///
/// To look at the settings while the app runs, open the kit with
/// ``present()``, or turn on its ``entryPoints``.
///
@MainActor
public final class AccessibilityKit {

    // MARK: - Public properties

    /// The shared instance.
    public static let shared = AccessibilityKit()

    // MARK: - Private properties

    private let monitor: AccessibilityMonitor
    private let coordinator: KitCoordinator

    // MARK: - Lifecycle

    init(monitor: AccessibilityMonitor = .shared) {
        self.monitor = monitor
        self.coordinator = KitCoordinator(monitor: monitor)
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
    /// An open Monitor is refreshed: a snapshot of the newly configured
    /// features is taken during this call, running their transforms, and
    /// delivered to it on the main queue. The session history the kit shows
    /// starts here, from the system's own values, so recording it runs no
    /// transform.
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
    /// Any number of observations can run side by side, and each receives
    /// every snapshot from its own first one on. Keep the returned
    /// ``AccessibilityObservation``: the observation ends when it is
    /// cancelled or released, and its completion is never called after
    /// that. Reconfiguring tracking does not end it, so capture the
    /// completion's owner weakly.
    ///
    /// - Parameter completion: Called with each snapshot. If tracking has
    ///   not been configured yet, no first snapshot is delivered; the
    ///   observation still stands, and receives changes once a
    ///   ``AccessibilityFetchType/continuous`` configuration is in place.
    /// - Returns: The observation. Keep it for as long as you want snapshots.
    ///
    public func observeAccessibilityTracking(completion: @escaping (AccessibilitySnapshot) -> Void) -> AccessibilityObservation {
        return monitor.observeAccessibilityTracking(completion: completion)
    }

    ///
    /// Opens the kit: a sheet over the app whose home lists the kit's tools.
    ///
    /// The sheet is shown from a window of the kit's own, above the app, so
    /// it can be opened from anywhere without a view controller. Calling this
    /// while the kit is open does nothing. Before a window scene is active,
    /// the kit opens as soon as one is.
    ///
    /// Use ``entryPoints`` to let people open the kit themselves.
    ///
    public func present() {
        coordinator.present()
    }

    ///
    /// The ways people can open the kit while the app runs.
    ///
    /// Empty by default. The kit is a debugging aid, so set this in debug
    /// builds only:
    ///
    /// ```swift
    /// #if DEBUG
    /// AccessibilityKit.shared.entryPoints = [.floatingButton, .shake]
    /// #endif
    /// ```
    ///
    public var entryPoints: Set<AccessibilityKitEntryPoint> {
        get { coordinator.entryPoints }
        set { coordinator.entryPoints = newValue }
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
    /// The monitor observes on its own, so presenting it does not affect an
    /// observation registered through
    /// ``observeAccessibilityTracking(completion:)``.
    ///
    /// - Parameter viewController: The view controller to present from.
    ///
    @available(*, deprecated, message: "Use present(), which opens the kit with the monitor in it, or entryPoints.")
    public func presentAccessibilityMonitor(on viewController: UIViewController) {
        let monitorViewController = UIHostingController(rootView: AccessibilityMonitorView(onDismiss: { viewController.dismiss(animated: true) }))

        viewController.present(
            monitorViewController,
            animated: true,
            completion: nil
        )
    }
}
