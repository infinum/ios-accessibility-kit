//
//  Bundle+Framework.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 06.03.2022..
//

import UIKit

extension Bundle {

    static func frameworkBundle(for aClass: AnyClass) -> Bundle {
        let bundle = Bundle(for: aClass)
        guard
            let path = bundle.path(forResource: "AccessibilityKit", ofType: "bundle"),
            let customBundle = Bundle(path: path)
        else { return bundle }
        return customBundle
    }
}
