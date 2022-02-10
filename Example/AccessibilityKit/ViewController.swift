//
//  ViewController.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

import UIKit
import AccessibilityKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        AccessibilityKit.shared.configureTracking(
            for: .boldText, .differentiateWithoutColor, .reduceMotion, .voiceOver
        )

        AccessibilityKit.shared.observeStateChanges { states in
            print("Observer changes...")
            states
                .forEach { state in
                    print("ID: \(state.identifier)")
                    print("Name: \(state.name)")
                    print("Enabled: \(state.enabled)")
                }
        }
    }
}
