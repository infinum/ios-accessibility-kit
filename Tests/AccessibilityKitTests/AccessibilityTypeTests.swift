//
//  AccessibilityTypeTests.swift
//  AccessibilityKitTests
//

import Testing
@testable import AccessibilityKit

@Suite("AccessibilityType")
struct AccessibilityTypeTests {

    ///
    /// The raw values are the default state identifiers, so they are the
    /// `identifier` a payload carries: renaming one is a wire-format change,
    /// not a rename. Listing them mirrors the README's feature table, and
    /// pins the order `allCases` hands to consumers along the way.
    ///
    @Test("Lists every case under its raw value")
    func listsEveryCaseUnderItsRawValue() {
        #expect(
            AccessibilityType.allCases.map(\.rawValue) == [
                "assistive_touch",
                "bold_text",
                "button_shapes",
                "closed_captioning",
                "cross_fade_transitions",
                "darker_system_colors",
                "differentiate_without_color",
                "font_scale",
                "grayscale",
                "guided_access",
                "invert_colors",
                "mono_audio",
                "on_off_switch_labels",
                "reduce_motion",
                "reduce_transparency",
                "shake_to_undo",
                "speak_screen",
                "speak_selection",
                "switch_control",
                "video_autoplay",
                "voice_over"
            ]
        )
    }
}
