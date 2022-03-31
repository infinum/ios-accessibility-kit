//
//  AccessibilityMonitorTableViewCell.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 11.02.2022..
//

import UIKit

final class AccessibilityMonitorTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var statusValueLabel: UILabel!
    @IBOutlet private weak var identifierTitleLabel: UILabel!
    @IBOutlet private weak var identifierValueLabel: UILabel!


    // MARK: - Public methods

    func configure(with item: AccessibilityState) {
        configureName(with: item.name)
        configureStatus(with: item.value)
        configureIdentifier(with: item.identifier)
    }
}

private extension AccessibilityMonitorTableViewCell {

    func configureName(with name: String) {
        nameLabel.text = name
    }

    func configureStatus(with value: AccessibilityValue) {
        switch value {
        case .number(let value):
            statusTitleLabel.text = "Value:"
            statusValueLabel.text = String(value)
        case .flag(let value):
            statusTitleLabel.text = "Enabled:"
            statusValueLabel.text = value ? "Yes" : "No"
            statusValueLabel.textColor = value ? .black : .darkGray
        }
    }

    func configureIdentifier(with value: String) {
        identifierTitleLabel.text = "Identifier:"
        identifierValueLabel.text = value
    }
}
