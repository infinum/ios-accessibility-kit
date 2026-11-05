//
//  AccessibilityGroup.swift
//  AccessibilityKit
//

import Foundation

///
/// The part of Settings -> Accessibility a feature belongs to.
///
/// The kit's Monitor lists features under these groups, in the order of
/// `allCases`.
///
public enum AccessibilityGroup: String, CaseIterable, Sendable {

    /// Features for seeing the screen: VoiceOver, text size, colour and contrast.
    case vision

    /// Features that reduce or replace movement on screen.
    case motion

    /// Features for audio and captions.
    case hearing

    /// Features that change how the device is operated.
    case interaction

    /// Features that read content aloud.
    case spokenContent = "spoken_content"

    /// A human-readable name for the group, suitable for display.
    public var displayName: String {
        switch self {
        case .vision:
            return "Vision"
        case .motion:
            return "Motion"
        case .hearing:
            return "Hearing"
        case .interaction:
            return "Interaction"
        case .spokenContent:
            return "Spoken content"
        }
    }
}

public extension AccessibilityType {

    /// The part of Settings -> Accessibility this feature belongs to.
    var group: AccessibilityGroup {
        switch self {
        case .voiceOver, .boldText, .fontScale, .buttonShapes, .darkerSystemColors, .invertColors,
             .grayscale, .differentiateWithoutColor, .reduceTransparency, .onOffSwitchLabels:
            return .vision
        case .reduceMotion, .crossFadeTransitions, .videoAutoplay:
            return .motion
        case .monoAudio, .closedCaptioning:
            return .hearing
        case .switchControl, .assistiveTouch, .guidedAccess, .shakeToUndo:
            return .interaction
        case .speakScreen, .speakSelection:
            return .spokenContent
        }
    }

    /// A human-readable name for the feature, in sentence case, suitable for display.
    var displayName: String {
        switch self {
        case .assistiveTouch: return "AssistiveTouch"
        case .boldText: return "Bold text"
        case .buttonShapes: return "Button shapes"
        case .closedCaptioning: return "Closed captioning"
        case .crossFadeTransitions: return "Cross-fade transitions"
        case .darkerSystemColors: return "Darker system colors"
        case .differentiateWithoutColor: return "Differentiate without color"
        case .fontScale: return "Font scale"
        case .grayscale: return "Grayscale"
        case .guidedAccess: return "Guided Access"
        case .invertColors: return "Invert colors"
        case .monoAudio: return "Mono audio"
        case .onOffSwitchLabels: return "On/off switch labels"
        case .reduceMotion: return "Reduce motion"
        case .reduceTransparency: return "Reduce transparency"
        case .shakeToUndo: return "Shake to undo"
        case .speakScreen: return "Speak screen"
        case .speakSelection: return "Speak selection"
        case .switchControl: return "Switch Control"
        case .videoAutoplay: return "Video autoplay"
        case .voiceOver: return "VoiceOver"
        }
    }

}

extension AccessibilityType {

    ///
    /// The system notification posted when this feature changes, which is
    /// what tracking listens to.
    ///
    @MainActor
    var notificationName: Notification.Name {
        return AccessibilityObjectFactory.object(for: self).notificationName
    }

    ///
    /// The order features are listed in within their group, matching the
    /// order of Settings -> Accessibility rather than the alphabet.
    ///
    static let displayOrder: [AccessibilityType] = [
        .voiceOver, .boldText, .fontScale, .buttonShapes, .darkerSystemColors, .invertColors,
        .grayscale, .differentiateWithoutColor, .reduceTransparency, .onOffSwitchLabels,
        .reduceMotion, .crossFadeTransitions, .videoAutoplay,
        .monoAudio, .closedCaptioning,
        .switchControl, .assistiveTouch, .guidedAccess, .shakeToUndo,
        .speakScreen, .speakSelection
    ]

    /// This feature's position in ``displayOrder``.
    var displayIndex: Int {
        return Self.displayIndices[self] ?? Self.displayOrder.count
    }

    private static let displayIndices = Dictionary(
        uniqueKeysWithValues: displayOrder.enumerated().map { ($0.element, $0.offset) }
    )
}
