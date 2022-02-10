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
            for: [.boldText, .buttonShapes, .onOffSwitchLabels, .reduceMotion, .reduceTransparency, .voiceOver]
        )
        return true
    }
}
