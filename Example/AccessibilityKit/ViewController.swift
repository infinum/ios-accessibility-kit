//
//  ViewController.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 08.02.2022..
//

import UIKit
import AccessibilityKit

class ViewController: UIViewController {

    @IBAction func buttonActionHandler(_ sender: UIButton) {
        AccessibilityKit.shared.presentAccessibilityMonitor(on: self)
    }
}
