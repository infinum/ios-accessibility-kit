//
//  KitValuePresentation.swift
//  AccessibilityKit
//

import Foundation

///
/// How a value is shown and spoken in the kit: "On", "Off", or a value such
/// as "1.12× · XL", spoken "1.12 times, XL".
///
struct KitValuePresentation: Equatable {

    enum Kind: Equatable {
        case on
        case off
        case value
    }

    let kind: Kind
    /// What is shown: "On", "Off", "1.12× · XL".
    let text: String
    /// What VoiceOver says: "on", "off", "1.12 times, XL".
    let spokenText: String

    init(value: AccessibilityValue, type: AccessibilityType) {
        switch value {
        case .flag(let isOn):
            kind = isOn ? .on : .off
            text = isOn ? "On" : "Off"
            spokenText = isOn ? "on" : "off"
        case .scale(let scale):
            kind = .value
            let number = Self.format(scale, with: Self.scaleFormatter)
            if type == .fontScale, let size = BodyTextSize.nearest(toScale: scale) {
                text = "\(number)× · \(size.shortName)"
                spokenText = "\(number) times, \(size.shortName)"
            } else {
                text = "\(number)×"
                spokenText = "\(number) times"
            }
        case .number(let number):
            kind = .value
            text = Self.format(number, with: Self.numberFormatter)
            spokenText = text
        case .percentage(let percentage):
            kind = .value
            text = Self.format(percentage, with: Self.percentFormatter)
            spokenText = text
        }
    }

    private static let scaleFormatter = KitShared(makeFormatter(style: .decimal, minimumFractionDigits: 2))
    private static let numberFormatter = KitShared(makeFormatter(style: .decimal, minimumFractionDigits: 0))
    private static let percentFormatter = KitShared(makeFormatter(style: .percent, minimumFractionDigits: 0))

    private static func format(_ value: Double, with formatter: KitShared<NumberFormatter>) -> String {
        return formatter.value.string(for: value) ?? "\(value)"
    }

    private static func makeFormatter(style: NumberFormatter.Style, minimumFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        // Follows the user's region as it changes.
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = style
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

///
/// A formatter shared across threads. Configured once and only read after,
/// and formatting is thread-safe, whether or not the SDK marks it `Sendable`.
///
struct KitShared<Value>: @unchecked Sendable {

    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
