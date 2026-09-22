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

    /// Read so the view is invalidated when the user changes their text size,
    /// which re-reads the snapshots below.
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
    /// the value where it is produced. The correction applies everywhere the
    /// library reports this feature, the accessibility monitor included.
    ///
    var correctedAtSource: String {
        do {
            let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
                for: [
                    AccessibilityTrackingObject(
                        type: .fontScale,
                        customIdentifier: "large_text_enabled",
                        transform: { value in .flag(Self.isLargeText(value)) }
                    )
                ]
            )
            return Self.label(for: snapshot)
        } catch {
            // The list above is unique, so this is a mistake in that list
            // rather than a runtime condition - the same stance the app's
            // own configuration takes.
            assertionFailure("Invalid accessibility tracking objects: \(error)")
            return "unavailable"
        }
    }

    ///
    /// The same correction applied to a snapshot that was already produced,
    /// for cases where the tracking configuration cannot be changed.
    ///
    var correctedAfterTheFact: String {
        do {
            let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
                for: [
                    AccessibilityTrackingObject(type: .fontScale),
                    AccessibilityTrackingObject(type: .voiceOver)
                ]
            )

            let corrected = AccessibilitySnapshot(
                states: snapshot.states.map { state in
                    guard state.type == .fontScale else { return state }
                    return state.withValue(.flag(Self.isLargeText(state.value)))
                }
            )
            return Self.label(for: corrected)
        } catch {
            // The list above is unique, so this is a mistake in that list
            // rather than a runtime condition - the same stance the app's
            // own configuration takes.
            assertionFailure("Invalid accessibility tracking objects: \(error)")
            return "unavailable"
        }
    }

    static func isLargeText(_ value: AccessibilityValue) -> Bool {
        return (value.scaleValue ?? 1) >= 1.2
    }

    static func label(for snapshot: AccessibilitySnapshot) -> String {
        return snapshot.states.first?.value.flagValue == true ? "on" : "off"
    }
}
