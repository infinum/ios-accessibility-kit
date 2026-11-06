//
//  KitWindows.swift
//  AccessibilityKit
//

import UIKit

///
/// Finds the app's window scenes and windows for the kit.
///
@MainActor
enum KitWindows {

    /// The key window of the app's active scene: the kit's own while it is open.
    static func keyWindow() -> UIWindow? {
        return activeWindowScene()?.windows.first { $0.isKeyWindow }
    }

    /// The app's own window in the scene: its key one, or failing that its first.
    static func hostWindow(in scene: UIWindowScene) -> UIWindow? {
        return scene.windows.first { $0.isKeyWindow && !($0 is KitOverlayWindow) }
            ?? scene.windows.first { !($0 is KitOverlayWindow) }
    }

    /// The app's window scene in use: the active one, or failing that one still in the foreground.
    static func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowApplication }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}
