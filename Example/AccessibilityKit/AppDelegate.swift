//
//  AppDelegate.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

import UIKit
import AccessibilityKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AccessibilityKit.shared.configureTracking(
            with: AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(type: .boldText),
                    AccessibilityTrackingObject(type: .buttonShapes),
                    AccessibilityTrackingObject(type: .reduceMotion),
                    AccessibilityTrackingObject(type: .voiceOver),
                    AccessibilityTrackingObject(type: .fontScale)
                ]
            )
        )
        return true
    }
}
