//
//  AccessibilityType.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

public enum AccessibilityType: String, Encodable {
    case assistiveTouch = "assistive_touch"
    case boldText = "bold_text"
    case buttonShapes = "button_shapes"
    case closedCaptioning = "closed_captioning"
    case crossFadeTransitions = "cross_fade_transitions"
    case darkerSystemColors = "darker_system_colors"
    case differentiateWithoutColor = "differentiate_without_color"
    case fontScale = "font_scale"
    case grayscale = "grayscale"
    case guidedAccess = "guided_access"
    case invertColors = "invert_colors"
    case monoAudio = "mono_audio"
    case onOffSwitchLabels = "on_off_switch_labels"
    case reduceMotion = "reduce_motion"
    case reduceTransparency = "reduce_transparency"
    case shakeToUndo = "shake_to_undo"
    case speakScreen = "speak_screen"
    case speakSelection = "speak_selection"
    case switchControl = "switch_control"
    case videoAutoplay = "video_autoplay"
    case voiceOver = "voice_over"
}
