//
//  BodyTextSize.swift
//  AccessibilityKit
//

import UIKit

///
/// The twelve Dynamic Type sizes, by the point size of body text at each.
///
/// The font scale is the body size over the default size's, so this one
/// table gives both the scale a size reports and the size a scale names.
///
/// Source: Human Interface Guidelines, Typography.
///
enum BodyTextSize: Double, CaseIterable {
    case xs = 14
    case s = 15
    case m = 16
    case l = 17
    case xl = 19
    case xxl = 21
    case xxxl = 23
    case ax1 = 28
    case ax2 = 33
    case ax3 = 40
    case ax4 = 47
    case ax5 = 53

    init(_ category: UIContentSizeCategory) {
        switch category {
        case .extraSmall: self = .xs
        case .small: self = .s
        case .medium: self = .m
        case .large: self = .l
        case .extraLarge: self = .xl
        case .extraExtraLarge: self = .xxl
        case .extraExtraExtraLarge: self = .xxxl
        case .accessibilityMedium: self = .ax1
        case .accessibilityLarge: self = .ax2
        case .accessibilityExtraLarge: self = .ax3
        case .accessibilityExtraExtraLarge: self = .ax4
        case .accessibilityExtraExtraExtraLarge: self = .ax5
        default: self = .l
        }
    }

    /// Body text at this size over body text at the default size.
    var scale: Double {
        return rawValue / BodyTextSize.l.rawValue
    }

    /// "XL", "AX3".
    var shortName: String {
        switch self {
        case .xs: return "XS"
        case .s: return "S"
        case .m: return "M"
        case .l: return "L"
        case .xl: return "XL"
        case .xxl: return "XXL"
        case .xxxl: return "XXXL"
        case .ax1: return "AX1"
        case .ax2: return "AX2"
        case .ax3: return "AX3"
        case .ax4: return "AX4"
        case .ax5: return "AX5"
        }
    }

    ///
    /// The size whose scale is closest, or `nil` for a scale more than half
    /// a step beyond the smallest or largest size, which no device setting
    /// produces.
    ///
    static func nearest(toScale scale: Double) -> BodyTextSize? {
        guard scale.isFinite,
              scale >= BodyTextSize.xs.scale - 0.03,
              scale <= BodyTextSize.ax5.scale + 0.18 else { return nil }
        return allCases.min(by: { abs($0.scale - scale) < abs($1.scale - scale) })
    }
}
