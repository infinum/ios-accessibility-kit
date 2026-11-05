//
//  AccessibilityKitEntryPoint.swift
//  AccessibilityKit
//

import Foundation

///
/// A way for people to open the kit while the app runs.
///
/// Set them on ``AccessibilityKit/entryPoints``.
///
public enum AccessibilityKitEntryPoint: Hashable, Sendable {

    ///
    /// A floating button above the app, in a window of the kit's own, so it
    /// never joins the app's view tree.
    ///
    /// Drag it to any corner, and it stays there across launches. Long-press
    /// it to hide it until the app is launched again.
    ///
    case floatingButton

    ///
    /// Shaking the device.
    ///
    /// Off unless you include it, so an app that uses shake to undo keeps it.
    /// The kit hears a shake when it reaches the app's window, so a view or
    /// view controller that handles shakes itself without passing them on
    /// to `super` keeps them from the kit while it is on screen.
    ///
    case shake
}
