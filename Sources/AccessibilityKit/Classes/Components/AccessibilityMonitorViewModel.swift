//
//  AccessibilityMonitorViewModel.swift
//  Pods
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

final class AccessibilityMonitorViewModel: ObservableObject {

    @Published var states: [AccessibilityState] = []

    init() {
        AccessibilityKit.shared.observeAccessibilityTracking { [weak self] snapshot in
            self?.states = snapshot.states
        }
    }

    private lazy var formatter = {
        return NumberFormatter()
    }()

    func color(for value: AccessibilityValue) -> Color {
        switch value {
        case .number, .percentage, .scale:
            Color(.label)
        case .flag(let value):
            value ? Color(.systemGreen) : Color(.secondaryLabel)
        }
    }

    func formattedValue(for value: AccessibilityValue) -> String {
        switch value {
        case .number(let value):
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            return formatter.string(for: value) ?? ""
        case .percentage(let value):
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 0
            return formatter.string(for: value) ?? ""
        case .scale(let value):
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return "\(formatter.string(for: value) ?? "")x"
        case .flag(let value):
            return value ? "Enabled" : "Disabled"
        }
    }
}
