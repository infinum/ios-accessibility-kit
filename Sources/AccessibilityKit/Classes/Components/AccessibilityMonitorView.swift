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
/// It observes through ``AccessibilityKit/observeAccessibilityTracking(completion:)``,
/// so tracking must be configured first, and values it shows carry any
/// transform the tracking objects apply.
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
