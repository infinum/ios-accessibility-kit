//
//  AccessibilityObjectFactoryTests.swift
//  AccessibilityKitTests
//

import Testing
import UIKit
@testable import AccessibilityKit

@Suite("AccessibilityObjectFactory")
@MainActor
struct AccessibilityObjectFactoryTests {

    @Test("Produces an object carrying the requested type", arguments: AccessibilityType.allCases)
    func producesMatchingType(type: AccessibilityType) {
        #expect(AccessibilityObjectFactory.object(for: type).type == type)
    }

    @Test("Produces an object with the expected name", arguments: AccessibilityType.allCases)
    func producesExpectedName(type: AccessibilityType) {
        #expect(AccessibilityObjectFactory.object(for: type).name == Self.expectedName(for: type))
    }

    @Test("Subscribes each object to the right notification", arguments: AccessibilityType.allCases)
    func producesExpectedNotificationName(type: AccessibilityType) {
        #expect(
            AccessibilityObjectFactory.object(for: type).notificationName
                == Self.expectedNotificationName(for: type)
        )
    }

    @Test("States carry the type's raw value as the default identifier", arguments: AccessibilityType.allCases)
    func producesDefaultIdentifier(type: AccessibilityType) {
        let state = AccessibilityObjectFactory.object(for: type).state(customIdentifier: nil)

        #expect(state.identifier == type.rawValue)
    }

    @Test("States carry the custom identifier they are given", arguments: AccessibilityType.allCases)
    func honoursCustomIdentifier(type: AccessibilityType) {
        let state = AccessibilityObjectFactory
            .object(for: type)
            .state(customIdentifier: "custom_\(type.rawValue)")

        #expect(state.identifier == "custom_\(type.rawValue)")
    }
}

// MARK: - Expectations

private extension AccessibilityObjectFactoryTests {

    ///
    /// Exhaustive switches: adding a case to `AccessibilityType` fails to
    /// compile here until both expectations are filled in. `allCases` then
    /// carries the new case into every test above automatically.
    ///
    static func expectedName(for type: AccessibilityType) -> String {
        switch type {
        case .assistiveTouch: return "Assistive Touch"
        case .boldText: return "Bold Text"
        case .buttonShapes: return "Button Shapes"
        case .closedCaptioning: return "Closed Captioning"
        case .crossFadeTransitions: return "Cross Fade Transitions"
        case .darkerSystemColors: return "Darker System Colors"
        case .differentiateWithoutColor: return "Differentiate Without Color"
        case .fontScale: return "Font Scale"
        case .grayscale: return "Grayscale"
        case .guidedAccess: return "Guided Access"
        case .invertColors: return "Invert Colors"
        case .monoAudio: return "Mono Audio"
        case .onOffSwitchLabels: return "On/Off Switch Labels"
        case .reduceMotion: return "Reduce Motion"
        case .reduceTransparency: return "Reduce Transparency"
        case .shakeToUndo: return "Shake To Undo"
        case .speakScreen: return "Speak Screen"
        case .speakSelection: return "Speak Selection"
        case .switchControl: return "Switch Control"
        case .videoAutoplay: return "Video Autoplay"
        case .voiceOver: return "VoiceOver"
        }
    }

    static func expectedNotificationName(for type: AccessibilityType) -> Notification.Name {
        switch type {
        case .assistiveTouch: return UIAccessibility.assistiveTouchStatusDidChangeNotification
        case .boldText: return UIAccessibility.boldTextStatusDidChangeNotification
        case .buttonShapes: return UIAccessibility.buttonShapesEnabledStatusDidChangeNotification
        case .closedCaptioning: return UIAccessibility.closedCaptioningStatusDidChangeNotification
        case .crossFadeTransitions: return UIAccessibility.prefersCrossFadeTransitionsStatusDidChange
        case .darkerSystemColors: return UIAccessibility.darkerSystemColorsStatusDidChangeNotification
        case .differentiateWithoutColor: return UIAccessibility.differentiateWithoutColorDidChangeNotification
        case .fontScale: return UIContentSizeCategory.didChangeNotification
        case .grayscale: return UIAccessibility.grayscaleStatusDidChangeNotification
        case .guidedAccess: return UIAccessibility.guidedAccessStatusDidChangeNotification
        case .invertColors: return UIAccessibility.invertColorsStatusDidChangeNotification
        case .monoAudio: return UIAccessibility.monoAudioStatusDidChangeNotification
        case .onOffSwitchLabels: return UIAccessibility.onOffSwitchLabelsDidChangeNotification
        case .reduceMotion: return UIAccessibility.reduceMotionStatusDidChangeNotification
        case .reduceTransparency: return UIAccessibility.reduceTransparencyStatusDidChangeNotification
        case .shakeToUndo: return UIAccessibility.shakeToUndoDidChangeNotification
        case .speakScreen: return UIAccessibility.speakScreenStatusDidChangeNotification
        case .speakSelection: return UIAccessibility.speakSelectionStatusDidChangeNotification
        case .switchControl: return UIAccessibility.switchControlStatusDidChangeNotification
        case .videoAutoplay: return UIAccessibility.videoAutoplayStatusDidChangeNotification
        case .voiceOver: return UIAccessibility.voiceOverStatusDidChangeNotification
        }
    }
}
