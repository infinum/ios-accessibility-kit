//
//  KitDateFormat.swift
//  AccessibilityKit
//

import Foundation

/// The times the kit shows, in the user's locale.
enum KitDateFormat {

    private static let shortFormatter = KitShared(makeFormatter(timeStyle: .short))
    private static let mediumFormatter = KitShared(makeFormatter(timeStyle: .medium))

    /// "14:02", in the user's locale.
    static func shortTime(_ date: Date) -> String {
        return shortFormatter.value.string(from: date)
    }

    /// "14:02:19", in the user's locale.
    static func mediumTime(_ date: Date) -> String {
        return mediumFormatter.value.string(from: date)
    }

    private static func makeFormatter(timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        // Follows the user's region and 12/24-hour setting as they change.
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = timeStyle
        return formatter
    }
}
