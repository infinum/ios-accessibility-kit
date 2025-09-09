//
//  AccessibilityMonitorView.swift
//  Pods
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

public struct AccessibilityMonitorView: View {

    @ObservedObject private var viewModel = AccessibilityMonitorViewModel()
    let onDismiss: () -> Void

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
