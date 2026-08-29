//
//  AccessibilityMonitorViewModel.swift
//  Pods
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

@MainActor
final class AccessibilityMonitorViewModel: ObservableObject {

    @Published var states: [AccessibilityState] = []

    private let monitor: AccessibilityMonitor

    init(monitor: AccessibilityMonitor = .shared) {
        self.monitor = monitor
        monitor.addSnapshotObserver(self)
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

// MARK: - AccessibilitySnapshotObserver

extension AccessibilityMonitorViewModel: AccessibilitySnapshotObserver {

    func accessibilitySnapshotDidChange(_ snapshot: AccessibilitySnapshot) {
        states = snapshot.states
    }
}
