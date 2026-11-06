//
//  FeatureDetailView.swift
//  AccessibilityKit
//

import SwiftUI
import UIKit

///
/// One setting: its current value, its identifier and notification, and
/// what it has done this session, newest first.
///
struct FeatureDetailView: View {

    @ObservedObject var model: AccessibilityMonitorViewModel
    let identifier: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var didCopy = false
    /// Bumped per copy, so an earlier copy's reset never clears a later one's "Copied".
    @State private var copyCount = 0

    var body: some View {
        Group {
            if let row = model.row(for: identifier) {
                content(for: row)
            } else {
                Text(verbatim: "This setting is no longer tracked.")
                    .font(.body)
                    .foregroundColor(KitColor.text2)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(KitColor.bg.ignoresSafeArea())
        // At accessibility sizes the name wraps in the content instead of
        // being cut off in the bar.
        .navigationTitle(Text(verbatim: dynamicTypeSize.isAccessibilitySize ? "" : title))
        .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
    }

    private var title: String {
        return model.row(for: identifier)?.name ?? identifier
    }

    private func content(for row: AccessibilityMonitorViewModel.Row) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    if dynamicTypeSize.isAccessibilitySize {
                        KitContentTitle(title: title)
                    }
                    Text(verbatim: row.type.group.displayName)
                        .font(.subheadline)
                        .foregroundColor(KitColor.text2)
                }

                currentValue(for: row)

                facts(for: row)

                session
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .kitReadableWidth()
        }
    }

    private func currentValue(for row: AccessibilityMonitorViewModel.Row) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            KitCaption(text: "Current value")
            Text(verbatim: row.presentation.text)
                .font(.title.bold().monospacedDigit())
                .foregroundColor(KitColor.text)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KitColor.sheet)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Current value, \(row.presentation.spokenText)"))
    }

    private func facts(for row: AccessibilityMonitorViewModel.Row) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                fact(title: "Identifier", value: row.identifier, font: .subheadline.monospaced())
                Button {
                    UIPasteboard.general.string = row.identifier
                    didCopy = true
                    copyCount += 1
                    let count = copyCount
                    KitAnnouncer.announcePolitely("Copied")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if count == copyCount { didCopy = false }
                    }
                } label: {
                    Text(verbatim: didCopy ? "Copied" : "Copy")
                }
                .buttonStyle(KitTextButtonStyle())
                .accessibilityLabel(Text(verbatim: "Copy identifier"))
            }
            .padding(.vertical, 12)
            .kitTopRule()

            fact(
                title: "Listens to",
                value: Self.breakable(row.type.feature.notification.rawValue),
                font: .footnote.monospaced()
            )
            .accessibilityLabel(Text(verbatim: "Listens to, \(row.type.feature.notification.rawValue)"))
            .padding(.vertical, 12)
            .kitTopRule()
            .overlay(KitColor.rule.frame(height: 1), alignment: .bottom)
        }
    }

    private func fact(title: String, value: String, font: Font) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            KitCaption(text: title)
            Text(verbatim: value)
                .font(font)
                .foregroundColor(KitColor.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var session: some View {
        VStack(alignment: .leading, spacing: 0) {
            KitSectionHeader(title: "This session", flush: true)

            let history = model.history(for: identifier)
            ForEach(Array(history.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 16) {
                    Text(verbatim: KitDateFormat.mediumTime(item.date))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(KitColor.text2)
                        .frame(minWidth: 72, alignment: .leading)
                    Text(verbatim: item.event)
                        .font(.body)
                        .foregroundColor(KitColor.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)
                .frame(minHeight: 56)
                .kitTopRule()
                .overlay(index == history.count - 1 ? KitColor.rule.frame(height: 1) : nil, alignment: .bottom)
                .accessibilityElement(children: .combine)
            }
        }
    }

    ///
    /// A notification name is one long camel-case word. A zero-width space
    /// where a lower-case letter meets a capital lets it break between words
    /// instead of anywhere, without splitting an acronym such as "UI".
    ///
    static func breakable(_ name: String) -> String {
        var result = ""
        var previous: Character?
        for character in name {
            if character.isUppercase, previous?.isLowercase == true {
                result.append("\u{200B}")
            }
            result.append(character)
            previous = character
        }
        return result
    }
}

