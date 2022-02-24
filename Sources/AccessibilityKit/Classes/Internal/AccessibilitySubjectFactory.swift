//
//  AccessibilitySubjectFactory.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

enum AccessibilitySubjectFactory {

    static func object(for type: AccessibilityType) -> AccessibilitySubject? {
        switch type {
        case .assistiveTouch:
            return AssistiveTouchAccessibilitySubject()
        case .boldText:
            return BoldTextAccessibilitySubject()
        case .buttonShapes:
            if #available(iOS 14.0, *) {
                return ButtonShapesAccessibilitySubject()
            } else {
                return nil
            }
        case .closedCaption:
            return ClosedCaptionAccessibilitySubject()
        case .crossFadeTransitions:
            if #available(iOS 14.0, *) {
                return CrossFadeTransitionsAccessibilitySubject()
            } else {
                return nil
            }
        case .darkSystemColors:
            return DarkSystemColorsAccessibilitySubject()
        case .differentiateWithoutColor:
            return DifferentiateWithoutColorAccessibilitySubject()
        case .grayscale:
            return GrayscaleAccessibilitySubject()
        case .guidedAccess:
            return GuidedAccessAccessibilitySubject()
        case .invertColors:
            return InvertColorsAccessibilitySubject()
        case .monoAudio:
            return MonoAudioAccessibilitySubject()
        case .onOffSwitchLabels:
            return OnOffSwitchLabelsAccessibilitySubject()
        case .reduceMotion:
            return ReduceMotionAccessibilitySubject()
        case .reduceTransparency:
            return ReduceTransparencyAccessibilitySubject()
        case .shakeToUndo:
            return ShakeToUndoAccessibilitySubject()
        case .speakScreen:
            return SpeakScreenAccessibilitySubject()
        case .speakSelection:
            return SpeakSelectionAccessibilitySubject()
        case .switchControl:
            return SwitchControlAccessibilitySubject()
        case .videoAutoplay:
            return VideoAutoplayAccessibilitySubject()
        case .voiceOver:
            return VoiceOverAccessibilitySubject()
        }
    }
}
