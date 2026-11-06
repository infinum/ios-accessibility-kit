//
//  KitOverlayWindow.swift
//  AccessibilityKit
//

import SwiftUI
import UIKit

///
/// A window above the app's, for everything the kit draws over it: the kit
/// button and the kit's sheet. Touches pass through to the app except on
/// the kit's own controls.
///
final class KitOverlayWindow: UIWindow {

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        windowLevel = .alert + 1
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        // The root view is the empty canvas around the kit's controls.
        return view === rootViewController?.view ? nil : view
    }
}

///
/// The overlay window's root: an empty, transparent view holding the kit
/// button. It defers the status bar, orientation, home indicator and edge
/// gestures to the app's own screen.
///
final class KitOverlayViewController: UIViewController {

    let kitButton = KitFloatingButton()

    /// The app's window, whose screen decides those.
    weak var hostWindow: UIWindow?

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(kitButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        kitButton.moveToCorner(animated: false)
    }

    // The app's top controller answers, through its own `childFor…` chain,
    // so a screen inside a navigation or tab controller decides as it would
    // without the kit.

    override var childForStatusBarStyle: UIViewController? {
        return hostViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return hostViewController
    }

    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return hostViewController
    }

    override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        return hostViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return hostViewController?.supportedInterfaceOrientations ?? .all
    }

    private var hostViewController: UIViewController? {
        return hostWindow?.rootViewController?.kitTopmostPresented
    }
}

///
/// Hosts the kit's sheet. Escape closes it, wherever focus is in the stack.
///
final class KitHostingController: UIHostingController<KitRootView> {

    var onEscape: (() -> Void)?
    /// Called once the kit's sheet has gone, however it was dismissed —
    /// including by the app dismissing whatever its key window presented.
    var onDidDismiss: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            onDidDismiss?()
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        let escape = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapePressed))
        escape.wantsPriorityOverSystemBehavior = true
        return (super.keyCommands ?? []) + [escape]
    }

    @objc
    private func escapePressed() {
        onEscape?()
    }
}

extension UIViewController {

    /// The controller at the top of the chain this one presents, skipping one being dismissed.
    var kitTopmostPresented: UIViewController {
        var controller = self
        while let presented = controller.presentedViewController, !presented.isBeingDismissed {
            controller = presented
        }
        return controller
    }
}
