//
//  AccessibilityType.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

// Keep the cases in alphabetical order, and keep every case available on
// every supported OS: `allCases` is public, so its order is the order
// consumers iterate, and marking a case `@available` stops `CaseIterable`
// synthesis - which would put a hand-written `allCases` into shipped code.

///
/// An accessibility feature that can be tracked.
///
/// Each case names one system-wide setting the user controls in Settings ->
/// Accessibility. The raw value is the identifier reported for that feature
/// when no custom identifier is supplied, and it is what appears in the
/// encoded output.
///
/// ## Discussion
///
/// Every feature reports a ``AccessibilityValue/flag(_:)`` — whether the
/// setting is on — except ``fontScale``, which reports a
/// ``AccessibilityValue/scale(_:)``.
///
/// Because the type is `CaseIterable`, every supported feature can be tracked
/// without naming them individually:
///
/// ```swift
/// let snapshot = AccessibilityKit.shared.currentAccessibilitySnapshot(
///     for: AccessibilityType.allCases.map { AccessibilityTrackingObject(type: $0) }
/// )
/// ```
///
public enum AccessibilityType: String, CaseIterable, Encodable {

    /// Whether AssistiveTouch is running, which replaces gestures the user
    /// cannot perform with an on-screen menu. Reports a flag.
    case assistiveTouch = "assistive_touch"

    /// Whether the user has asked for text to be drawn in a heavier weight.
    /// Reports a flag.
    case boldText = "bold_text"

    /// Whether buttons are drawn with a visible shape rather than as bare
    /// text. Reports a flag.
    case buttonShapes = "button_shapes"

    /// Whether closed captioning and SDH subtitles are preferred for video.
    /// Reports a flag.
    case closedCaptioning = "closed_captioning"

    /// Whether sliding screen transitions are replaced with a cross fade.
    /// Reports a flag.
    case crossFadeTransitions = "cross_fade_transitions"

    /// Whether the user has asked for darker system colours, which increases
    /// contrast. Reports a flag.
    case darkerSystemColors = "darker_system_colors"

    /// Whether the user needs meaning conveyed by something other than colour
    /// alone, such as a shape or a label. Reports a flag.
    case differentiateWithoutColor = "differentiate_without_color"

    /// How much larger or smaller the user's preferred text is than the
    /// default. Reports a scale, where `1.0` is the default text size.
    case fontScale = "font_scale"

    /// Whether the display is rendered in greyscale. Reports a flag.
    case grayscale = "grayscale"

    /// Whether Guided Access is limiting the device to a single app.
    /// Reports a flag.
    case guidedAccess = "guided_access"

    /// Whether display colours are inverted. Reports a flag.
    case invertColors = "invert_colors"

    /// Whether stereo audio is played as mono, for users with hearing loss in
    /// one ear. Reports a flag.
    case monoAudio = "mono_audio"

    /// Whether switches show on/off labels in addition to their position.
    /// Reports a flag.
    case onOffSwitchLabels = "on_off_switch_labels"

    /// Whether the user has asked to reduce motion, such as parallax and
    /// animated transitions. Reports a flag.
    case reduceMotion = "reduce_motion"

    /// Whether the user has asked to reduce transparency and blur effects.
    /// Reports a flag.
    case reduceTransparency = "reduce_transparency"

    /// Whether shaking the device offers to undo the last action.
    /// Reports a flag.
    case shakeToUndo = "shake_to_undo"

    /// Whether Speak Screen is enabled, which reads the screen aloud on
    /// request. Reports a flag.
    case speakScreen = "speak_screen"

    /// Whether Speak Selection is enabled, which offers to read selected text
    /// aloud. Reports a flag.
    case speakSelection = "speak_selection"

    /// Whether Switch Control is running, which drives the device with
    /// adaptive switches. Reports a flag.
    case switchControl = "switch_control"

    /// Whether video is allowed to play automatically. Reports a flag.
    case videoAutoplay = "video_autoplay"

    /// Whether VoiceOver, the screen reader, is running. Reports a flag.
    case voiceOver = "voice_over"
}
