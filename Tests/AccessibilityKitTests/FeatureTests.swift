//
//  FeatureTests.swift
//  AccessibilityKitTests
//

import Testing
import UIKit
@testable import AccessibilityKit

@Suite("Feature")
struct FeatureTests {

    ///
    /// A feature listening to the wrong notification never updates, and
    /// nothing else would notice: its value would just stay as first read.
    ///
    @Test("Listens to the right notification for every feature", arguments: AccessibilityType.allCases)
    func listensToTheRightNotification(type: AccessibilityType) {
        #expect(type.feature.notification == Self.expectedNotification(for: type))
    }
}

// MARK: - Expectations

private extension FeatureTests {

    ///
    /// Written out separately from the feature table, so a slip in either
    /// shows. An exhaustive switch: a new feature does not compile here until
    /// its notification is filled in.
    ///
    static func expectedNotification(for type: AccessibilityType) -> Notification.Name {
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
