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
@MainActor
final class KitCoordinator: NSObject {

    // MARK: - Internal properties

    var entryPoints: Set<AccessibilityKitEntryPoint> = [] {
        didSet { entryPointsDidChange() }
    }

    // MARK: - Private properties

    private let tracker: AccessibilityTracker
    private var window: KitOverlayWindow?
    private var overlayController: KitOverlayViewController?
    private weak var kitController: KitHostingController?
    private weak var previousKeyWindow: UIWindow?
    private var sceneActivationObserver: NSObjectProtocol?
    private var sceneDisconnectionObserver: NSObjectProtocol?
    /// `present()` was called before a window scene was active.
    private var isPresentationPending = false
    /// The kit button was long-pressed away until the next launch.
    private var isButtonHiddenUntilRelaunch = false
    /// A screen tool is running on the app, with the kit closed.
    private var isScreenToolRunning = false

    // MARK: - Lifecycle

    init(tracker: AccessibilityTracker) {
        self.tracker = tracker
        super.init()
    }

    // MARK: - Internal methods

    func present() {
        guard kitController == nil, !isScreenToolRunning else { return }
        guard let window = makeWindowIfPossible(), let root = window.rootViewController else {
            isPresentationPending = true
            waitForActiveScene()
            return
        }
        isPresentationPending = false
        // Still mid-transition from the last time; a later tap or shake opens it.
        guard root.presentedViewController == nil else { return }

        let model = AccessibilityMonitorViewModel(tracker: tracker)
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
        updateVisibility()
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
        guard kitController != nil else { return }
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
            ?? window?.windowScene.flatMap(Self.hostWindow(in:))
            ?? Self.activeWindowScene().flatMap(Self.hostWindow(in:))
        appWindow?.makeKey()
        previousKeyWindow = nil
        updateVisibility()
    }

    ///
    /// A screen tool works on the app, so the kit closes first and the
    /// button stays hidden until the tool finishes. Finishing returns to the
    /// app, not to the kit home. A screen tool must call `finish` on every
    /// way out, or the kit stays closed for the rest of the session.
    ///
    func start(_ kind: KitToolKind) {
        guard case .screenTool(let start) = kind else { return }

        isScreenToolRunning = true
        dismiss { [weak self] in
            start {
                self?.isScreenToolRunning = false
                self?.updateVisibility()
            }
        }
    }

    func entryPointsDidChange() {
        if entryPoints.contains(.shake) {
            KitShakeDetector.installIfNeeded()
            KitShakeDetector.onShake = { [weak self] in self?.present() }
        } else {
            KitShakeDetector.onShake = nil
        }

        if entryPoints.contains(.floatingButton), makeWindowIfPossible() == nil {
            waitForActiveScene()
        } else if entryPoints.isEmpty, !isPresentationPending, let sceneActivationObserver {
            // Nothing is waiting for a scene any more.
            NotificationCenter.default.removeObserver(sceneActivationObserver)
            self.sceneActivationObserver = nil
        }
        updateVisibility()
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
            if windowScene.activationState != .foregroundActive, kitController == nil,
               let activeScene = Self.activeWindowScene(), activeScene !== windowScene {
                window.windowScene = activeScene
                overlayController?.hostWindow = Self.hostWindow(in: activeScene)
                observeDisconnection(of: activeScene)
            }
            return window
        }
        guard let scene = Self.activeWindowScene() else { return nil }

        let overlayController = KitOverlayViewController()
        overlayController.hostWindow = Self.hostWindow(in: scene)
        overlayController.kitButton.addTarget(self, action: #selector(kitButtonTapped), for: .primaryActionTriggered)
        overlayController.kitButton.onHide = { [weak self] in self?.hideButtonUntilRelaunch() }

        let window = KitOverlayWindow(windowScene: scene)
        window.rootViewController = overlayController
        self.window = window
        self.overlayController = overlayController
        observeDisconnection(of: scene)
        updateVisibility()
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
        guard !entryPoints.isEmpty || isPresentationPending else { return }

        // Another window of the app may already be active, and would send no
        // activation of its own.
        if makeWindowIfPossible() == nil {
            waitForActiveScene()
        } else if isPresentationPending {
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
        // Whatever ran in the gone scene ended with it.
        kitController = nil
        previousKeyWindow = nil
        isScreenToolRunning = false
    }

    ///
    /// The kit button shows while its entry point is on, unless it was
    /// hidden until relaunch, the kit is open, or a screen tool runs. The
    /// window shows only while it has something on it.
    ///
    func updateVisibility() {
        guard let window, let overlayController else { return }

        let showsButton = entryPoints.contains(.floatingButton)
            && !isButtonHiddenUntilRelaunch
            && kitController == nil
            && !isScreenToolRunning
        overlayController.kitButton.isHidden = !showsButton
        window.isHidden = !(showsButton || kitController != nil)
    }

    func hideButtonUntilRelaunch() {
        isButtonHiddenUntilRelaunch = true
        updateVisibility()

        let reopen = entryPoints.contains(.shake) ? " Shake the device to open the kit." : ""
        KitAnnouncer.announcePolitely("Accessibility Kit button hidden until the app is launched again.\(reopen)")
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

    func sceneDidActivate() {
        guard makeWindowIfPossible() != nil else { return }

        if let sceneActivationObserver {
            NotificationCenter.default.removeObserver(sceneActivationObserver)
            self.sceneActivationObserver = nil
        }
        if isPresentationPending {
            present()
        }
    }
}

// MARK: - Windows

extension KitCoordinator {

    /// The key window of the app's active scene: the kit's own while it is open.
    static func keyWindow() -> UIWindow? {
        return activeWindowScene()?.windows.first { $0.isKeyWindow }
    }

    static func hostWindow(in scene: UIWindowScene) -> UIWindow? {
        return scene.windows.first { $0.isKeyWindow && !($0 is KitOverlayWindow) }
            ?? scene.windows.first { !($0 is KitOverlayWindow) }
    }

    static func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowApplication }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}

private extension UIScene.ActivationState {

    var isConnected: Bool {
        return self != .unattached
    }
}
