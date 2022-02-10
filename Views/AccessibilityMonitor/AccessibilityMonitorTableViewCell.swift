//
//  AccessibilityMonitorTableViewCell.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 11.02.2022..
//

import UIKit

class AccessibilityMonitorTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var enabledSwitch: UISwitch!

    func configure(title: String, enabled: Bool) {
        titleLabel.text = title
        enabledSwitch.isOn = enabled
    }
}
