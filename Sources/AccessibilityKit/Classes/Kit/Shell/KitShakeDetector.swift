//
//  KitShakeDetector.swift
//  AccessibilityKit
//

import ObjectiveC
import UIKit

///
/// Hears shakes for the kit's shake entry point.
///
/// A shake goes to the first responder and travels up the responder chain to
/// the app's window. The kit has no place in that chain, so it adds a
/// `motionEnded(_:with:)` of its own to `UIWindow` that calls the one it
/// replaces first, then reports the shake. It is installed only once the
/// shake entry point is turned on, and does nothing while it is off.
///
@MainActor
enum KitShakeDetector {

    /// Called on every shake while set.
    static var onShake: (() -> Void)?

    private static var isInstalled = false

    static func installIfNeeded() {
        guard !isInstalled else { return }
        isInstalled = true

        let selector = #selector(UIResponder.motionEnded(_:with:))
        guard let method = class_getInstanceMethod(UIWindow.self, selector) else { return }

        typealias MotionEnded = @convention(c) (AnyObject, Selector, UIEvent.EventSubtype, UIEvent?) -> Void
        let original = unsafeBitCast(method_getImplementation(method), to: MotionEnded.self)

        let replacement: @convention(block) (AnyObject, UIEvent.EventSubtype, UIEvent?) -> Void = { window, motion, event in
            original(window, selector, motion, event)
            guard motion == .motionShake else { return }
            MainActor.assumeIsolated { KitShakeDetector.onShake?() }
        }
        let implementation = imp_implementationWithBlock(replacement)

        // `UIWindow` inherits the method from `UIResponder`. Adding it to
        // `UIWindow` leaves every other responder alone; replacing is only
        // for an SDK where `UIWindow` already has its own.
        if !class_addMethod(UIWindow.self, selector, implementation, method_getTypeEncoding(method)) {
            method_setImplementation(method, implementation)
        }
    }
}
