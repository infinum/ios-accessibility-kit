//
//  UITableView+Dequeue.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 01.04.2022..
//

import UIKit

extension UITableView {

    func dequeueReusableCell<T: UITableViewCell>(
        ofType type: T.Type,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: type)
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! T
    }
}
