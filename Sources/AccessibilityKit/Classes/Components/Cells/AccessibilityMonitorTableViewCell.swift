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
    @IBOutlet private weak var statusValueLabel: UILabel!
    @IBOutlet private weak var identifierValueLabel: UILabel!

    // MARK: - Public methods

    func configure(with item: AccessibilityState, formatter: NumberFormatter) {
        configureName(with: item.name)
        configureValue(with: item.value, formatter: formatter)
        configureIdentifier(with: item.identifier)
    }
}

// MARK: - Private methods

private extension AccessibilityMonitorTableViewCell {

    func configureName(with name: String) {
        nameLabel.text = name
    }

    func configureValue(with value: AccessibilityValue, formatter: NumberFormatter) {
        switch value {
        case .number(let value):
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            statusValueLabel.text = formatter.string(for: value)
            statusValueLabel.textColor = .label
        case .percentage(let value):
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 0
            statusValueLabel.text = formatter.string(for: value)
            statusValueLabel.textColor = .label
        case .scale(let value):
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            statusValueLabel.text = "\(formatter.string(for: value) ?? "")x"
            statusValueLabel.textColor = .label
        case .flag(let value):
            statusValueLabel.text = value ? "Enabled" : "Disabled"
            statusValueLabel.textColor = value ? .systemGreen : .secondaryLabel
        }
    }

    func configureIdentifier(with value: String) {
        identifierValueLabel.text = value
    }
}
