//
//  FontScaleAccessibilityObjectTests.swift
//  AccessibilityKitTests
//

import Testing
import UIKit
@testable import AccessibilityKit

@Suite("FontScaleAccessibilityObject")
struct FontScaleAccessibilityObjectTests {

    ///
    /// Scales are the category's `body` size divided by the `large`
    /// (default) body size of 17pt, per the Human Interface Guidelines.
    ///
    static let mapping: [(category: UIContentSizeCategory, size: Double)] = [
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
        let object = FontScaleAccessibilityObject(contentSizeCategory: { category })

        #expect(object.state(customIdentifier: nil).value == .scale(size / 17.0))
    }

    @Test("Falls back to the default scale for an unknown category")
    func fallsBackForUnknownCategory() {
        let object = FontScaleAccessibilityObject(
            contentSizeCategory: { UIContentSizeCategory(rawValue: "not a real category") }
        )

        #expect(object.state(customIdentifier: nil).value == .scale(1.0))
    }

    @Test("Reports the scale under the font scale identity")
    func reportsFontScaleIdentity() {
        let state = FontScaleAccessibilityObject(contentSizeCategory: { .large })
            .state(customIdentifier: nil)

        #expect(state.type == .fontScale)
        #expect(state.identifier == "font_scale")
    }
}
