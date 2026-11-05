//
//  FontScaleAccessibilityObject.swift
//  
//
//  Created by Nikola Majcen on 26.03.2022..
//

import UIKit

@MainActor
struct FontScaleAccessibilityObject: AccessibilityObject {

    // MARK: - Private properties

    private let contentSizeCategory: @MainActor () -> UIContentSizeCategory

    // MARK: - Lifecycle

    init(
        contentSizeCategory: @escaping @MainActor () -> UIContentSizeCategory
            = { UIApplication.shared.preferredContentSizeCategory }
    ) {
        self.contentSizeCategory = contentSizeCategory
    }

    // MARK: - Public properties

    var type: AccessibilityType {
        return .fontScale
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

    ///
    /// Font scale is the `body` size of the preferred category over the
    /// `body` size of the default (`large`) category.
    ///
    var fontScale: Double {
        return BodyTextSize(contentSizeCategory()).scale
    }
}
