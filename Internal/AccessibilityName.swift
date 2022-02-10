//
//  AccessibilityName.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

enum AccessibilityName {

    static func name(for type: AccessibilityType) -> String {
        switch type {
        case .assistiveTouch:
            return "Assistive Touch"
        case .boldText:
            return "Bold Text"
        case .buttonShapes:
            return "Button Shapes"
        case .closedCaption:
            return "Closed Caption"
        case .crossFadeTransitions:
            return "Cross Fade Transitions"
        case .darkSystemColors:
            return "Dark System Colors"
        case .differentiateWithoutColor:
            return "Differentiate Without Color"
        case .grayscale:
            return "Grayscale"
        case .guidedAccess:
            return "Guided Access"
        case .invertColors:
            return "Invert Colors"
        case .monoAudio:
            return "Mono Audio"
        case .onOffSwitchLabels:
            return "On Off Switch Labels"
        case .reduceMotion:
            return "Reduce Motion"
        case .reduceTransparency:
            return "Reduce Transparency"
        case .shakeToUndo:
            return "Shake To Undo"
        case .speakScreen:
            return "Speak Screen"
        case .speakSelection:
            return "Speak Selection"
        case .switchControl:
            return "Switch Control"
        case .videoAutoplay:
            return "Video Autoplay"
        case .voiceOver:
            return "VoiceOver"
        }
    }
}
