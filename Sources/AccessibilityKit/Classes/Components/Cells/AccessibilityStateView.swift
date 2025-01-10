//
//  AccessibilityStateView.swift
//  Pods
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

struct AccessibilityStateView: View {

    let name: String
    let identifier: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("ID: \(identifier)")
                    .font(.caption)
            }
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(valueColor)
        }
        .padding(15)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(10)
    }
}
