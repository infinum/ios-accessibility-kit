//
//  KitPresenceTests.swift
//  AccessibilityKitTests
//

import Testing
@testable import AccessibilityKit

@Suite("KitPresence")
struct KitPresenceTests {

    @Test("Shows the button only while the floating button entry point is on")
    func showsTheButtonWhileItsEntryPointIsOn() {
        var presence = KitPresence()
        #expect(!presence.showsButton)
        #expect(!presence.showsWindow)

        presence.entryPoints = [.shake]
        #expect(!presence.showsButton)
        #expect(!presence.showsWindow)

        presence.entryPoints = [.floatingButton]
        #expect(presence.showsButton)
        #expect(presence.showsWindow)
    }

    ///
    /// The kit's sheet is shown from the window, so the window stays while
    /// the kit is open even with no button on it.
    ///
    @Test("Hides the button while the kit is open, keeping the window for it")
    func hidesTheButtonWhileTheKitIsOpen() {
        var presence = KitPresence(entryPoints: [.floatingButton])

        presence.kitDidOpen()
        #expect(!presence.showsButton)
        #expect(presence.showsWindow)
        #expect(!presence.mayOpen)

        presence.kitDidClose()
        #expect(presence.showsButton)
        #expect(presence.showsWindow)
        #expect(presence.mayOpen)
    }

    @Test("Keeps the button hidden until relaunch, whatever the entry points do after")
    func keepsTheButtonHiddenUntilRelaunch() {
        var presence = KitPresence(entryPoints: [.floatingButton])

        _ = presence.hideButtonUntilRelaunch()
        #expect(!presence.showsButton)
        #expect(!presence.showsWindow)

        presence.entryPoints = []
        presence.entryPoints = [.floatingButton]
        #expect(!presence.showsButton)
        #expect(!presence.showsWindow)
    }

    ///
    /// With the button gone, shaking is the only way left to open the kit
    /// by hand, so the announcement points to it when it is on.
    ///
    @Test("Mentions shaking in the hidden-button announcement only while shake is on")
    func mentionsShakingOnlyWhileShakeIsOn() {
        var buttonOnly = KitPresence(entryPoints: [.floatingButton])
        var buttonAndShake = KitPresence(entryPoints: [.floatingButton, .shake])

        #expect(buttonOnly.hideButtonUntilRelaunch() == "Accessibility Kit button hidden until the app is launched again.")
        #expect(buttonAndShake.hideButtonUntilRelaunch() == "Accessibility Kit button hidden until the app is launched again. Shake the device to open the kit.")
    }

    ///
    /// A screen tool is started from the kit home, so it starts while the
    /// kit is open, and the kit closes for it to work on the app.
    ///
    @Test("Hides the button while a screen tool runs, and brings it back when the tool finishes")
    func hidesTheButtonWhileAScreenToolRuns() {
        var presence = KitPresence(entryPoints: [.floatingButton])
        presence.kitDidOpen()

        presence.screenToolDidStart()
        presence.kitDidClose()
        #expect(!presence.showsButton)
        #expect(!presence.showsWindow)
        #expect(!presence.mayOpen)

        presence.screenToolDidFinish()
        #expect(presence.showsButton)
        #expect(presence.mayOpen)
    }

    ///
    /// Opening the kit makes its window, so shake alone never needs one
    /// ahead. The button does, and so does an opening asked for before any
    /// window scene was active, until the kit opens.
    ///
    @Test("Needs the window ahead only while the floating button is on or an opening is pending")
    func needsTheWindowAheadOnlyForTheButtonOrAPendingOpening() {
        var presence = KitPresence()
        #expect(!presence.needsWindowAhead)

        presence.entryPoints = [.shake]
        #expect(!presence.needsWindowAhead)

        presence.openingWaitsForScene()
        #expect(presence.isOpeningPending)
        #expect(presence.needsWindowAhead)

        presence.kitDidOpen()
        #expect(!presence.isOpeningPending)
        #expect(!presence.needsWindowAhead)

        presence.kitDidClose()
        presence.entryPoints = [.floatingButton]
        #expect(presence.needsWindowAhead)
    }

    ///
    /// The window's scene went away, an iPad window closed say, and took
    /// the kit's sheet and anything a screen tool showed with it. An opening
    /// still waiting happens on the next scene.
    ///
    @Test("Losing the scene closes the kit and ends a screen tool, keeping a pending opening")
    func losingTheSceneClosesTheKitAndEndsAScreenTool() {
        var openKit = KitPresence(entryPoints: [.floatingButton])
        openKit.kitDidOpen()
        openKit.sceneDidDisconnect()
        #expect(openKit.showsButton)
        #expect(openKit.mayOpen)

        var runningTool = KitPresence(entryPoints: [.floatingButton])
        runningTool.kitDidOpen()
        runningTool.screenToolDidStart()
        runningTool.kitDidClose()
        runningTool.sceneDidDisconnect()
        #expect(runningTool.showsButton)
        #expect(runningTool.mayOpen)

        var pendingOpening = KitPresence()
        pendingOpening.openingWaitsForScene()
        pendingOpening.sceneDidDisconnect()
        #expect(pendingOpening.isOpeningPending)
    }
}
