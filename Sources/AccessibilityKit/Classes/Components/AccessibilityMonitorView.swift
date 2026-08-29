//
//  AccessibilityMonitorView.swift
//  Pods
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

///
/// A screen listing the tracked accessibility features and their values.
///
/// Present it with ``AccessibilityKit/presentAccessibilityMonitor(on:)`` from
/// UIKit, or embed this view directly in SwiftUI:
///
/// ```swift
/// .sheet(isPresented: $isPresented) {
///     AccessibilityMonitorView { isPresented = false }
/// }
/// ```
///
/// It observes the configured tracking on its own — presenting it does not
/// replace a completion the app registered through
/// ``AccessibilityKit/observeAccessibilityTracking(completion:)``. Tracking
/// must be configured first, and values it shows carry any transform the
/// tracking objects apply.
///
/// - Important: Only one observation is active at a time, so showing the
///   monitor replaces the app's own. Register again once it is dismissed.
///
public struct AccessibilityMonitorView: View {

    @ObservedObject private var viewModel = AccessibilityMonitorViewModel()
    let onDismiss: () -> Void

    ///
    /// Creates the accessibility monitor.
    ///
    /// - Parameter onDismiss: Called when the user taps the close button. The
    ///   monitor does not dismiss itself.
    ///
    public init(onDismiss: @escaping () -> Void ) {
        self.onDismiss = onDismiss
    }

    ///
    /// The monitor's content: one row per tracked accessibility feature,
    /// showing its name, the identifier it is reported under, and its current
    /// value.
    ///
    public var body: some View {
        NavigationView {
            ZStack {
                backgroundColor

                ScrollView {
                    accessibilityStateListView
                        .navigationTitle("Accessibility Kit")
                        .toolbar { toolbarButton }
                }
            }
        }
    }
}

private extension AccessibilityMonitorView {

    var backgroundColor: some View {
        Color(.systemGray5).edgesIgnoringSafeArea(.all)
    }

    var accessibilityStateListView: some View {
        VStack {
            ForEach(viewModel.states) { state in
                AccessibilityStateView(
                    name: state.name,
                    identifier: state.identifier,
                    value: viewModel.formattedValue(for: state.value),
                    valueColor: viewModel.color(for: state.value)
                )
            }

        }
    }

    var toolbarButton: some ToolbarContent {
        ToolbarItem {
            Button(
                action: { onDismiss() },
                label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color(.systemGray6))
                        .background(Color.gray)
                        .clipShape(Circle())
                }
            )
        }
    }
}
