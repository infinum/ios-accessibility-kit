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

    var body: some View {
        Button("Accessibility tracking") {
            self.presentingModal = true
        }
        .sheet(isPresented: $presentingModal) {
            AccessibilityMonitorView { self.presentingModal = false }
        }
    }
}
