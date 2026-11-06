//
//  KitCoordinator.swift
//  AccessibilityKit
//

import SwiftUI
import UIKit

///
/// Runs the kit: its overlay window, its button and shake entry points, and
/// the sheet whose root is the kit home.
///
/// What to show and when the kit may open is decided by ``KitPresence``;
/// the coordinator reports each event to it and puts the window, the
/// button and the sheet right.
///
@MainActor
final class KitCoordinator: NSObject {

    // MARK: - Internal properties

    var entryPoints: Set<AccessibilityKitEntryPoint> {
        get { presence.entryPoints }
        set {
            presence.entryPoints = newValue
            entryPointsDidChange()
        }
    }

    // MARK: - Private properties

    private let tracker: AccessibilityTracker
    /// Every change puts the button, the window and the wait for a scene right.
    private var presence = KitPresence() {
        didSet { updateForPresence() }
    }
    private var window: KitOverlayWindow?
    private var overlayController: KitOverlayViewController?
    /// The kit's sheet, held to dismiss it and to match its dismissal report.
    private weak var kitController: KitHostingController?
    private weak var previousKeyWindow: UIWindow?
    private var sceneActivationObserver: NSObjectProtocol?
    private var sceneDisconnectionObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    init(tracker: AccessibilityTracker) {
        self.tracker = tracker
        super.init()
    }

    // MARK: - Internal methods

    func present() {
        guard presence.mayOpen else { return }
        guard let window = makeWindowIfPossible(), let root = window.rootViewController else {
            presence.openingWaitsForScene()
            waitForActiveScene()
            return
        }
        // Still mid-transition from the last time; a later tap or shake opens it.
        // An opening that waited for a scene never stops here: the window it
        // finds is new, with nothing presented on it.
        guard root.presentedViewController == nil else { return }

        let model = KitModel(tracker: tracker)
        let controller = KitHostingController(
            rootView: KitRootView(
                model: model,
                tools: KitToolRegistry.tools,
                close: { [weak self] in self?.dismiss() },
                startScreenTool: { [weak self] kind in self?.start(kind) }
            )
        )
        controller.onEscape = { [weak self] in self?.dismiss() }
        controller.onDidDismiss = { [weak self, weak controller] in
            guard let self, let controller, self.kitController === controller else { return }
            self.kitDidClose()
        }

        if window.traitCollection.userInterfaceIdiom == .pad || window.traitCollection.horizontalSizeClass == .regular {
            controller.modalPresentationStyle = .formSheet
        } else {
            controller.modalPresentationStyle = .pageSheet
            controller.sheetPresentationController?.detents = [.large()]
            controller.sheetPresentationController?.prefersGrabberVisible = true
        }
        controller.presentationController?.delegate = self

        previousKeyWindow = window.windowScene?.windows.first { $0.isKeyWindow && $0 !== window }
        kitController = controller
        presence.kitDidOpen()
        // Key, so hardware-keyboard commands such as Escape reach the kit.
        window.makeKey()
        root.present(controller, animated: true)

        // UIKit can still refuse; then nothing is open, so nothing may look open.
        if root.presentedViewController !== controller {
            kitDidClose()
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension KitCoordinator: UIAdaptivePresentationControllerDelegate {

    /// Swiped down rather than closed with the button. The sheet's own
    /// dismissal report usually comes first, which makes this a no-op.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard presence.isKitOpen else { return }
        kitDidClose()
    }
}

// MARK: - Private methods

private extension KitCoordinator {

    func dismiss(completion: (() -> Void)? = nil) {
        guard let kitController, let presenter = kitController.presentingViewController else {
            completion?()
            return
        }
        // Dismissed from below, so whatever the kit presented itself — the
        // share sheet — closes with it. The sheet reports its own dismissal.
        presenter.dismiss(animated: true, completion: completion)
    }

    func kitDidClose() {
        kitController = nil
        // Back to the app's window, so the overlay never keeps key status
        // once the kit is closed.
        let appWindow = previousKeyWindow
            ?? window?.windowScene.flatMap(KitWindows.hostWindow(in:))
            ?? KitWindows.activeWindowScene().flatMap(KitWindows.hostWindow(in:))
        appWindow?.makeKey()
        previousKeyWindow = nil
        presence.kitDidClose()
    }

    ///
    /// A screen tool works on the app, so the kit closes first and the
    /// button stays hidden until the tool finishes. Finishing returns to the
    /// app, not to the kit home. A screen tool must call `finish` on every
    /// way out: until it does, the kit stays closed.
    ///
    func start(_ kind: KitToolKind) {
        guard case .screenTool(let start) = kind else { return }

        presence.screenToolDidStart()
        dismiss { [weak self] in
            start {
                self?.presence.screenToolDidFinish()
            }
        }
    }

    func entryPointsDidChange() {
        if presence.entryPoints.contains(.shake) {
            KitShakeDetector.installIfNeeded()
            KitShakeDetector.onShake = { [weak self] in self?.present() }
        } else {
            KitShakeDetector.onShake = nil
        }

        if presence.needsWindowAhead, makeWindowIfPossible() == nil {
            waitForActiveScene()
        }
    }

    ///
    /// Puts the button and the window right for the kit's presence, and
    /// stops waiting for a scene once no window is needed ahead.
    ///
    func updateForPresence() {
        if !presence.needsWindowAhead {
            stopWaitingForActiveScene()
        }
        guard let window, let overlayController else { return }

        overlayController.kitButton.isHidden = !presence.showsButton
        window.isHidden = !presence.showsWindow
    }

    /// The overlay window, made on the app's active window scene if there is one.
    func makeWindowIfPossible() -> KitOverlayWindow? {
        if let window {
            guard let windowScene = window.windowScene, windowScene.activationState.isConnected else {
                discardWindow()
                return makeWindowIfPossible()
            }
            // With several windows of the app open, the kit follows the one
            // in use, so it never opens in a scene nobody can see.
            if windowScene.activationState != .foregroundActive, !presence.isKitOpen,
               let activeScene = KitWindows.activeWindowScene(), activeScene !== windowScene {
                window.windowScene = activeScene
                overlayController?.hostWindow = KitWindows.hostWindow(in: activeScene)
                observeDisconnection(of: activeScene)
            }
            return window
        }
        guard let scene = KitWindows.activeWindowScene() else { return nil }

        let overlayController = KitOverlayViewController()
        overlayController.hostWindow = KitWindows.hostWindow(in: scene)
        overlayController.kitButton.addTarget(self, action: #selector(kitButtonTapped), for: .primaryActionTriggered)
        overlayController.kitButton.onHide = { [weak self] in self?.hideButtonUntilRelaunch() }

        let window = KitOverlayWindow(windowScene: scene)
        window.rootViewController = overlayController
        self.window = window
        self.overlayController = overlayController
        observeDisconnection(of: scene)
        updateForPresence()
        return window
    }

    ///
    /// The window's scene went away — an iPad window closed, a discarded
    /// scene — so the window is dropped and the kit moves to the next scene
    /// to become active.
    ///
    func observeDisconnection(of scene: UIWindowScene) {
        if let sceneDisconnectionObserver {
            NotificationCenter.default.removeObserver(sceneDisconnectionObserver)
        }
        sceneDisconnectionObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: scene,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.windowSceneDidDisconnect() }
        }
    }

    func windowSceneDidDisconnect() {
        discardWindow()
        guard presence.needsWindowAhead else { return }

        // Another window of the app may already be active, and would send no
        // activation of its own.
        if makeWindowIfPossible() == nil {
            waitForActiveScene()
        } else if presence.isOpeningPending {
            present()
        }
    }

    func discardWindow() {
        if let sceneDisconnectionObserver {
            NotificationCenter.default.removeObserver(sceneDisconnectionObserver)
            self.sceneDisconnectionObserver = nil
        }
        window?.isHidden = true
        window = nil
        overlayController = nil
        kitController = nil
        previousKeyWindow = nil
        presence.sceneDidDisconnect()
    }

    func hideButtonUntilRelaunch() {
        let announcement = presence.hideButtonUntilRelaunch()
        KitAnnouncer.announcePolitely(announcement)
    }

    @objc
    func kitButtonTapped() {
        present()
    }

    ///
    /// Before a scene is active — when the kit is set up in the app's
    /// initialiser — the window waits for one.
    ///
    func waitForActiveScene() {
        guard sceneActivationObserver == nil else { return }

        sceneActivationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.sceneDidActivate() }
        }
    }

    func stopWaitingForActiveScene() {
        guard let sceneActivationObserver else { return }

        NotificationCenter.default.removeObserver(sceneActivationObserver)
        self.sceneActivationObserver = nil
    }

    func sceneDidActivate() {
        guard makeWindowIfPossible() != nil else { return }

        stopWaitingForActiveScene()
        if presence.isOpeningPending {
            present()
        }
    }
}

private extension UIScene.ActivationState {

    var isConnected: Bool {
        return self != .unattached
    }
}
