//
//  AccessibilityMonitorView.swift
//  AccessibilityKit
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

///
/// The kit's Monitor on its own: the tracked accessibility features and
/// their values, searchable and filterable, each with its session history.
///
/// The kit shows the same screen, so most apps open it with
/// ``AccessibilityKit/present()`` or ``AccessibilityKit/entryPoints``.
/// Embed this view to show the Monitor somewhere of your own:
///
/// ```swift
/// .sheet(isPresented: $isPresented) {
///     AccessibilityMonitorView { isPresented = false }
/// }
/// ```
///
/// It observes the configured tracking on its own, so it does not affect an
/// observation the app registered through
/// ``AccessibilityKit/observeAccessibilityTracking(completion:)``. The values
/// it shows carry any transform the tracking objects apply. It explains how
/// to set up tracking until tracking is configured, follows changes only
/// when tracking is configured with ``AccessibilityFetchType/continuous``,
/// and is refreshed whenever tracking is configured again.
///
public struct AccessibilityMonitorView: View {

    // `@StateObject`, not `@ObservedObject`: an observed object built inline
    // is re-created whenever the containing view rebuilds this one. Each new
    // model registers afresh and, under `.initial`, shows the values from the
    // rebuild rather than from when the Monitor was presented.
    @StateObject private var model = KitModel()
    let onDismiss: () -> Void

    ///
    /// Creates the accessibility monitor.
    ///
    /// - Parameter onDismiss: Called when the user taps the close button or
    ///   presses Escape. The monitor does not dismiss itself.
    ///
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    ///
    /// The Monitor in a navigation stack of its own, with a close button.
    ///
    public var body: some View {
        KitNavigationContainer {
            MonitorScreen(model: model)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        KitCloseButton(action: onDismiss)
                            .keyboardShortcut(.cancelAction)
                    }
                }
        }
        .tint(KitColor.text)
    }
}
