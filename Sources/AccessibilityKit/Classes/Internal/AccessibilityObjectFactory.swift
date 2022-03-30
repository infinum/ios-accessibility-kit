//
//  AccessibilityObjectFactory.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 10.02.2022..
//

import Foundation

enum AccessibilityObjectFactory {

    static func object(for type: AccessibilityType) -> AccessibilityObject {
        switch type {
        case .assistiveTouch:
            return AssistiveTouchAccessibilityObject()
        case .boldText:
            return BoldTextAccessibilityObject()
        case .buttonShapes:
            if #available(iOS 14.0, *) {
                return ButtonShapesAccessibilityObject()
            } else {
                fatalError("This functionality is available from iOS 14.0 and above.")
            }
        case .closedCaptioning:
            return ClosedCaptioningAccessibilityObject()
        case .crossFadeTransitions:
            if #available(iOS 14.0, *) {
                return CrossFadeTransitionsAccesibilityObject()
            } else {
                fatalError("This functionality is available from iOS 14.0 and above.")
            }
        case .darkerSystemColors:
            return DarkerSystemColorsAccessibilityObject()
        case .differentiateWithoutColor:
            return DifferentiateWithoutColorAccessibilityObject()
        case .fontScale:
            return FontScaleAccessibilityObject()
        case .grayscale:
            return GrayscaleAccessibilityObject()
        case .guidedAccess:
            return GuidedAccessAccessibilityObject()
        case .invertColors:
            return InvertColorsAccessibilityObject()
        case .monoAudio:
            return MonoAudioAccessibilityObject()
        case .onOffSwitchLabels:
            return OnOffSwitchLabelsAccessibilityObject()
        case .reduceMotion:
            return ReduceMotionAccessibilityObject()
        case .reduceTransparency:
            return ReduceTransparencyAccessibilityObject()
        case .shakeToUndo:
            return ShakeToUndoAccessibilityObject()
        case .speakScreen:
            return SpeakScreenAccessibilityObject()
        case .speakSelection:
            return SpeakSelectionAccessibilityObject()
        case .switchControl:
            return SwitchControlAccessibilityObject()
        case .videoAutoplay:
            return VideoAutoplayAccessibilityObject()
        case .voiceOver:
            return VoiceOverAccessibilityObject()
        }
    }
}
