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
        guard let accessibilityMonitor = AccessibilityMonitorViewController.loadViewController() else { return }
        present(accessibilityMonitor, animated: true, completion: nil)

        AccessibilityKit.shared.observeTrackingChanges { snapshot in
            print(snapshot.toDictionary())
        }
    }
}
