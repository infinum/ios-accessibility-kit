//
//  FontScaleAccessibilityObject.swift
//  
//
//  Created by Nikola Majcen on 26.03.2022..
//

import UIKit

struct FontScaleAccessibilityObject: AccessibilityObject {

    // MARK: - Public properties

    var type: AccessibilityType {
        return .fontScale
    }

    var name: String {
        return "Font scale"
    }

    var notificationName: Notification.Name {
        return UIContentSizeCategory.didChangeNotification
    }

    // MARK: - Public methods

    func state(customIdentifier: String?) -> AccessibilityState {
        return AccessibilityState(
            type: type,
            name: name,
            value: .scale(fontScale),
            customIdentifier: customIdentifier
        )
    }
}

// MARK: - Private methods

private extension FontScaleAccessibilityObject {

    // MARK: - Constants

    ///
    /// Values are defined based on the Human Interface guidelines.
    /// As a default value is used the `body` size for every category.
    ///
    /// Source: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography
    ///
    enum FontSize: Double {
        case xs   = 14.0
        case s    = 15.0
        case m    = 16.0
        case l    = 17.0
        case xl   = 19.0
        case xxl  = 21.0
        case xxxl = 23.0
        case ax1  = 28.0
        case ax2  = 33.0
        case ax3  = 40.0
        case ax4  = 47.0
        case ax5  = 53.0
    }

    // MARK: - Calculations

    ///
    /// Font scale is defined by `body` size of the category.
    /// The `large` category is set as a default (normal) scale.
    ///
    var fontScale: Double {
        let preferredFontSize = preferredFontSize(
            for: UIApplication.shared.preferredContentSizeCategory
        )
        return preferredFontSize.rawValue / FontSize.l.rawValue
    }

    func preferredFontSize(for contentSizeCategory: UIContentSizeCategory) -> FontSize {
        switch contentSizeCategory {
        case .extraSmall:
            return .xs
        case .small:
            return .s
        case .medium:
            return .m
        case .large:
            return .l
        case .extraLarge:
            return .xl
        case .extraExtraLarge:
            return .xxl
        case .extraExtraExtraLarge:
            return .xxxl
        case .accessibilityMedium:
            return .ax1
        case .accessibilityLarge:
            return .ax2
        case .accessibilityExtraLarge:
            return .ax3
        case .accessibilityExtraExtraLarge:
            return .ax4
        case .accessibilityExtraExtraExtraLarge:
            return .ax5
        default:
            return .l
        }
    }
}
