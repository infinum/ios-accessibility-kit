//
//  AccessibilityMonitorTableViewCell.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 11.02.2022..
//

import UIKit

class AccessibilityMonitorTableViewCell: UITableViewCell {

    @IBOutlet private weak var statusContainerView: UIView!
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var settingsActionButton: UIButton!

    func configure(title: String, enabled: Bool) {
        titleLabel.text = title

        statusContainerView.layer.cornerRadius = statusContainerView.bounds.height / 2
        statusContainerView.backgroundColor = enabled ? greenColor : greyColor
        statusContainerView.layer.borderColor = blueishColor.cgColor
        statusContainerView.layer.borderWidth = 1

        statusImageView.backgroundColor = .clear
        statusImageView.image = enabled ? checkmarkImage?.withRenderingMode(.alwaysTemplate) : nil
        statusImageView.tintColor = .white

        settingsActionButton.layer.cornerRadius = 8
        settingsActionButton.setImage(arrowImage, for: .normal)
        settingsActionButton.backgroundColor = blueishColor
        settingsActionButton.tintColor = darkBlueColor
        settingsActionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }

    var checkmarkImage: UIImage? {
        return UIImage(
            named: "Checkmark",
            in: Bundle(for: AccessibilityMonitorTableViewCell.self),
            with: nil
        )
    }

    var arrowImage: UIImage? {
        return UIImage(
            named: "RightArrow",
            in: Bundle(for: AccessibilityMonitorTableViewCell.self),
            with: nil
        )
    }

    var greenColor: UIColor {
        return UIColor(red: 38/255.0, green: 194/255.0, blue: 129/255.0, alpha: 1)
    }

    var greyColor: UIColor {
        return UIColor(red: 236/255.0, green: 236/255.0, blue: 236/255.0, alpha: 1)
    }

    var blueishColor: UIColor {
        return UIColor(red: 218/255.0, green: 223/255.0, blue: 225/255.0, alpha: 1)
    }

    var darkBlueColor: UIColor {
        return UIColor(red: 108/255.0, green: 122/255.0, blue: 137/255.0, alpha: 1)
    }
}
