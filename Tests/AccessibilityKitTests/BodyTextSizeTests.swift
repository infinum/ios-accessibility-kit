//
//  BodyTextSizeTests.swift
//  AccessibilityKitTests
//

import Testing
import UIKit
@testable import AccessibilityKit

///
/// The font scale tracking reports is the preferred category's `body` size
/// over the default one's, so this mapping is the font scale feature.
///
@Suite("BodyTextSize")
struct BodyTextSizeTests {

    ///
    /// Scales are the category's `body` size divided by the `large`
    /// (default) body size of 17pt, per the Human Interface Guidelines.
    ///
    nonisolated static let mapping: [(category: UIContentSizeCategory, size: Double)] = [
        (.extraSmall, 14.0),
        (.small, 15.0),
        (.medium, 16.0),
        (.large, 17.0),
        (.extraLarge, 19.0),
        (.extraExtraLarge, 21.0),
        (.extraExtraExtraLarge, 23.0),
        (.accessibilityMedium, 28.0),
        (.accessibilityLarge, 33.0),
        (.accessibilityExtraLarge, 40.0),
        (.accessibilityExtraExtraLarge, 47.0),
        (.accessibilityExtraExtraExtraLarge, 53.0)
    ]

    @Test("Maps every content size category to its scale", arguments: mapping)
    func mapsCategoryToScale(category: UIContentSizeCategory, size: Double) {
        #expect(BodyTextSize(category).scale == size / 17.0)
    }

    @Test("Falls back to the default scale for an unknown category")
    func fallsBackForUnknownCategory() {
        #expect(BodyTextSize(UIContentSizeCategory(rawValue: "not a real category")).scale == 1.0)
    }
}
