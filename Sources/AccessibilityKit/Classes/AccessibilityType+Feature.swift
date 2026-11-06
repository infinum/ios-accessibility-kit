//
//  AccessibilityType+Feature.swift
//  AccessibilityKit
//

import UIKit

///
/// Reads a feature's current state, as the system reports it, under its
/// default identifier.
///
typealias AccessibilityStateReader = @MainActor (AccessibilityType) -> AccessibilityState

///
/// What the library knows about one feature: what it is called, where
/// Settings lists it, the notification the system posts when it changes,
/// and how its current value is read.
///
struct Feature: Sendable {

    let name: String
    let group: AccessibilityGroup
    let notificationName: Notification.Name
    let read: @MainActor @Sendable () -> AccessibilityValue
}

public extension AccessibilityType {

    /// The part of Settings -> Accessibility this feature belongs to.
    var group: AccessibilityGroup {
        return feature.group
    }

    /// A human-readable name for the feature, in sentence case, suitable for display.
    var displayName: String {
        return feature.name
    }
}

extension AccessibilityType {

    ///
    /// Reads the system's state for a feature. The reader used outside tests.
    ///
    @MainActor
    static func readSystemState(_ type: AccessibilityType) -> AccessibilityState {
        return AccessibilityState(type: type, name: type.displayName, value: type.feature.read())
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

    ///
    /// This feature's entry, one per feature, in Settings order. Adding a
    /// feature means adding its entry here and its place in ``displayOrder``.
    ///
    var feature: Feature {
        switch self {

        // Vision

        case .voiceOver:
            return Feature(
                name: "VoiceOver",
                group: .vision,
                notificationName: UIAccessibility.voiceOverStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isVoiceOverRunning) }
            )
        case .boldText:
            return Feature(
                name: "Bold text",
                group: .vision,
                notificationName: UIAccessibility.boldTextStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isBoldTextEnabled) }
            )
        case .fontScale:
            // The `body` size of the preferred category over the `body` size
            // of the default (`large`) one.
            return Feature(
                name: "Font scale",
                group: .vision,
                notificationName: UIContentSizeCategory.didChangeNotification,
                read: { .scale(BodyTextSize(UIApplication.shared.preferredContentSizeCategory).scale) }
            )
        case .buttonShapes:
            return Feature(
                name: "Button shapes",
                group: .vision,
                notificationName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
                read: { .flag(UIAccessibility.buttonShapesEnabled) }
            )
        case .darkerSystemColors:
            return Feature(
                name: "Darker system colors",
                group: .vision,
                notificationName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isDarkerSystemColorsEnabled) }
            )
        case .invertColors:
            return Feature(
                name: "Invert colors",
                group: .vision,
                notificationName: UIAccessibility.invertColorsStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isInvertColorsEnabled) }
            )
        case .grayscale:
            return Feature(
                name: "Grayscale",
                group: .vision,
                notificationName: UIAccessibility.grayscaleStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isGrayscaleEnabled) }
            )
        case .differentiateWithoutColor:
            return Feature(
                name: "Differentiate without color",
                group: .vision,
                notificationName: UIAccessibility.differentiateWithoutColorDidChangeNotification,
                read: { .flag(UIAccessibility.shouldDifferentiateWithoutColor) }
            )
        case .reduceTransparency:
            return Feature(
                name: "Reduce transparency",
                group: .vision,
                notificationName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isReduceTransparencyEnabled) }
            )
        case .onOffSwitchLabels:
            return Feature(
                name: "On/off switch labels",
                group: .vision,
                notificationName: UIAccessibility.onOffSwitchLabelsDidChangeNotification,
                read: { .flag(UIAccessibility.isOnOffSwitchLabelsEnabled) }
            )

        // Motion

        case .reduceMotion:
            return Feature(
                name: "Reduce motion",
                group: .motion,
                notificationName: UIAccessibility.reduceMotionStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isReduceMotionEnabled) }
            )
        case .crossFadeTransitions:
            return Feature(
                name: "Cross-fade transitions",
                group: .motion,
                notificationName: UIAccessibility.prefersCrossFadeTransitionsStatusDidChange,
                read: { .flag(UIAccessibility.prefersCrossFadeTransitions) }
            )
        case .videoAutoplay:
            return Feature(
                name: "Video autoplay",
                group: .motion,
                notificationName: UIAccessibility.videoAutoplayStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isVideoAutoplayEnabled) }
            )

        // Hearing

        case .monoAudio:
            return Feature(
                name: "Mono audio",
                group: .hearing,
                notificationName: UIAccessibility.monoAudioStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isMonoAudioEnabled) }
            )
        case .closedCaptioning:
            return Feature(
                name: "Closed captioning",
                group: .hearing,
                notificationName: UIAccessibility.closedCaptioningStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isClosedCaptioningEnabled) }
            )

        // Interaction

        case .switchControl:
            return Feature(
                name: "Switch Control",
                group: .interaction,
                notificationName: UIAccessibility.switchControlStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isSwitchControlRunning) }
            )
        case .assistiveTouch:
            return Feature(
                name: "AssistiveTouch",
                group: .interaction,
                notificationName: UIAccessibility.assistiveTouchStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isAssistiveTouchRunning) }
            )
        case .guidedAccess:
            return Feature(
                name: "Guided Access",
                group: .interaction,
                notificationName: UIAccessibility.guidedAccessStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isGuidedAccessEnabled) }
            )
        case .shakeToUndo:
            return Feature(
                name: "Shake to undo",
                group: .interaction,
                notificationName: UIAccessibility.shakeToUndoDidChangeNotification,
                read: { .flag(UIAccessibility.isShakeToUndoEnabled) }
            )

        // Spoken content

        case .speakScreen:
            return Feature(
                name: "Speak screen",
                group: .spokenContent,
                notificationName: UIAccessibility.speakScreenStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isSpeakScreenEnabled) }
            )
        case .speakSelection:
            return Feature(
                name: "Speak selection",
                group: .spokenContent,
                notificationName: UIAccessibility.speakSelectionStatusDidChangeNotification,
                read: { .flag(UIAccessibility.isSpeakSelectionEnabled) }
            )
        }
    }
}
