//
//  KitColor.swift
//  AccessibilityKit
//

import SwiftUI
import UIKit

///
/// The kit's semantic colour roles. Each is an asset-catalog colour set with
/// Any, Dark and High Contrast appearances, so SwiftUI and UIKit switch on
/// their own, trait overrides included. Views use these, never a hex value.
///
enum KitColor {

    /// Screen background, tool sheets, tool bar.
    static let bg = color("kitBg")
    /// Grouped panels, icon-button fill, tool tiles.
    static let sheet = color("kitSheet")
    /// Primary text, icons in buttons.
    static let text = color("kitText")
    /// Secondary text, chevrons, section headers.
    static let text2 = color("kitText2")
    /// Dividers, tool-sheet edge.
    static let rule = color("kitRule")
    /// Search and chip outlines.
    static let field = color("kitField")
    /// Primary button fill, issue markers, badges.
    static let action = color("kitAction")
    /// Text buttons (Copy, Reset).
    static let actionText = color("kitActionText")
    /// Text on `action`.
    static let onAction = color("kitOnAction")
    /// Live dot, Changed dot.
    static let indicator = color("kitIndicator")
    /// Selected chip, kit button.
    static let selected = color("kitSelected")
    /// Text and icon on `selected`.
    static let onSelected = color("kitOnSelected")
    /// Pressed rows and chips.
    static let pressed = color("kitPressed")
    /// Disabled text and icons.
    static let disabled = color("kitDisabled")
    /// Disabled primary button.
    static let disabledFill = color("kitDisabledFill")
    /// Keyboard focus ring.
    static let focus = color("kitFocus")

    private static func color(_ name: String) -> Color {
        return Color(name, bundle: .module)
    }
}

extension UIColor {

    /// A kit colour role for UIKit views, by its asset name.
    static func kit(_ name: String) -> UIColor {
        return UIColor(named: name, in: .module, compatibleWith: nil) ?? .label
    }
}
