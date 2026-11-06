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
