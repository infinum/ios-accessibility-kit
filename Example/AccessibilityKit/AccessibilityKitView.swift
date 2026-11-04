//
//  AccessibilityKitView.swift
//  Example
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import AccessibilityKit
import SwiftUI

struct AccessibilityKitView: View {

    @State var presentingModal = false
    // Declared so the labels below are re-evaluated when the text size changes.
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        VStack(spacing: 20) {
            Button("Accessibility tracking") {
                self.presentingModal = true
            }

            Text("Corrected at the source: \(correctedAtSource)")
            Text("Corrected after the fact: \(correctedAfterTheFact)")
        }
        .sheet(isPresented: $presentingModal) {
            AccessibilityMonitorView { self.presentingModal = false }
        }
    }
}

private extension AccessibilityKitView {

    ///
    /// Reports the font scale as a plain "large text enabled" flag by correcting
    /// the value where it is produced. Passed here, it corrects only this
    /// snapshot; to correct observed snapshots and the accessibility monitor
    /// too, pass the same tracking object to `configureAccessibilityTracking(with:)`.
    ///
    var correctedAtSource: String {
        let snapshot = AccessibilityKit.shared.currentAccessibilitySnapshot(
            for: [
                AccessibilityTrackingObject(
                    type: .fontScale,
                    customIdentifier: "large_text_enabled",
                    transform: { value in .flag(value.isLargeText) }
                )
            ]
        )
        return Self.label(for: snapshot)
    }

    ///
    /// The same correction applied to a snapshot that was already produced,
    /// for cases where the tracking configuration cannot be changed.
    ///
    var correctedAfterTheFact: String {
        let snapshot = AccessibilityKit.shared.currentAccessibilitySnapshot(
            for: [
                AccessibilityTrackingObject(type: .fontScale),
                AccessibilityTrackingObject(type: .voiceOver)
            ]
        )

        let corrected = AccessibilitySnapshot(
            states: snapshot.states.map { state in
                guard state.type == .fontScale else { return state }
                return state.withValue(.flag(state.value.isLargeText))
            }
        )
        return Self.label(for: corrected)
    }

    static func label(for snapshot: AccessibilitySnapshot) -> String {
        let fontScale = snapshot.states.first { $0.type == .fontScale }
        return fontScale?.value.flagValue == true ? "on" : "off"
    }
}

private extension AccessibilityValue {

    // Kept off the view, which is main actor isolated, so the `@Sendable`
    // transform above can call it.
    var isLargeText: Bool {
        return (scaleValue ?? 1) >= 1.2
    }
}
