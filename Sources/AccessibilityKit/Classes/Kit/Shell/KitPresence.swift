//
//  KitPresence.swift
//  AccessibilityKit
//

import Foundation

///
/// Where the kit is over the app: open, waiting to open, or out of the way
/// for a screen tool, and so whether its button and window show.
///
/// The coordinator reports each event as it happens, and asks these
/// questions to put the button, the window and the wait for a scene right.
///
struct KitPresence {

    // MARK: - Internal properties

    var entryPoints: Set<AccessibilityKitEntryPoint> = []

    /// The kit's sheet is open, or on its way.
    private(set) var isKitOpen = false

    /// The kit was asked to open before any window scene was active, and
    /// opens once one is.
    private(set) var isOpeningPending = false

    /// A request to open the kit is not turned away: it is closed, and no screen tool runs.
    var mayOpen: Bool {
        return !isKitOpen && !isScreenToolRunning
    }

    ///
    /// The kit button shows while its entry point is on, unless it was
    /// hidden until relaunch, the kit is open, or a screen tool runs.
    ///
    var showsButton: Bool {
        return entryPoints.contains(.floatingButton) && !isButtonHiddenUntilRelaunch && mayOpen
    }

    /// The window shows only while it has something on it: the button, or the kit's sheet.
    var showsWindow: Bool {
        return showsButton || isKitOpen
    }

    ///
    /// The window should be made before anyone opens the kit: for the
    /// button, or for an opening that is waiting. Opening the kit makes
    /// the window anyway, so shake alone never needs it ahead.
    ///
    var needsWindowAhead: Bool {
        return entryPoints.contains(.floatingButton) || isOpeningPending
    }

    // MARK: - Private properties

    /// The kit button was long-pressed away until the next launch.
    private var isButtonHiddenUntilRelaunch = false

    /// A screen tool is working on the app, with the kit closed.
    private var isScreenToolRunning = false

    // MARK: - Internal methods

    /// The kit was asked to open with no window scene active.
    mutating func openingWaitsForScene() {
        isOpeningPending = true
    }

    mutating func kitDidOpen() {
        isKitOpen = true
        isOpeningPending = false
    }

    /// The kit's sheet has gone, however it was dismissed, or UIKit refused to show it.
    mutating func kitDidClose() {
        isKitOpen = false
    }

    /// Started from the kit home, so while the kit is open; the kit closes next.
    mutating func screenToolDidStart() {
        isScreenToolRunning = true
    }

    mutating func screenToolDidFinish() {
        isScreenToolRunning = false
    }

    ///
    /// The window's scene went away, and whatever ran in it ended with it:
    /// the kit's sheet and a screen tool. An opening still waiting happens
    /// on the next scene.
    ///
    mutating func sceneDidDisconnect() {
        isKitOpen = false
        isScreenToolRunning = false
    }

    /// Hides the button until the next launch, and returns what to announce.
    mutating func hideButtonUntilRelaunch() -> String {
        isButtonHiddenUntilRelaunch = true
        let reopen = entryPoints.contains(.shake) ? " Shake the device to open the kit." : ""
        return "Accessibility Kit button hidden until the app is launched again.\(reopen)"
    }
}
