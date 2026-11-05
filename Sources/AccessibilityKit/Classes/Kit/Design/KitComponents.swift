//
//  KitComponents.swift
//  AccessibilityKit
//

import SwiftUI

// MARK: - Layout

extension View {

    ///
    /// Keeps a single column at most 672 pt wide, centred, so landscape and
    /// iPad keep the phone layout.
    ///
    func kitReadableWidth() -> some View {
        frame(maxWidth: 672, alignment: .leading)
            .frame(maxWidth: .infinity)
    }

    /// A 1 pt `rule` line along the top edge, inset from the leading edge.
    func kitTopRule(leadingInset: CGFloat = 0) -> some View {
        overlay(
            KitColor.rule
                .frame(height: 1)
                .padding(.leading, leadingInset),
            alignment: .top
        )
    }
}

///
/// A navigation stack on iOS 16 and later, a stack-style navigation view
/// before that.
///
struct KitNavigationContainer<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content)
                .navigationViewStyle(.stack)
        }
    }
}

// MARK: - Text

/// Caption, Medium, uppercase, 0.2 pt tracking, `text-2`: section headers and fact titles.
struct KitCaption: View {

    let text: String

    var body: some View {
        Text(verbatim: text)
            .tracking(0.2)
            .font(.caption.weight(.medium))
            .textCase(.uppercase)
            .foregroundColor(KitColor.text2)
    }
}

/// Caption, Medium, uppercase, 0.2 pt tracking, `text-2`.
struct KitSectionHeader: View {

    let title: String
    var flush = false

    var body: some View {
        KitCaption(text: title)
            .padding(.top, flush ? 0 : 16)
            .padding(.horizontal, flush ? 0 : 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

///
/// A screen's title as wrapping Large Title text in the content. Used at
/// accessibility text sizes, where a bar title stays on one line and would
/// cut a long name off.
///
struct KitContentTitle: View {

    let title: String

    var body: some View {
        Text(verbatim: title)
            .font(.largeTitle.bold())
            .foregroundColor(KitColor.text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Live dot

///
/// A 6 pt `indicator` dot: filled while tracking is live, a hollow ring for
/// a one-time snapshot. Decorative, so hidden from VoiceOver.
///
struct KitLiveDot: View {

    var isHollow = false

    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = 6

    var body: some View {
        Group {
            if isHollow {
                Circle().strokeBorder(KitColor.indicator, lineWidth: 1.5)
            } else {
                Circle().fill(KitColor.indicator)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Status

///
/// On is a checkmark and Semibold "On", off is `text-2` "Off", any other
/// value is Semibold tabular figures. Never colour alone.
///
struct KitStatusView: View {

    let presentation: KitValuePresentation

    var body: some View {
        Group {
            switch presentation.kind {
            case .on:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                    Text(verbatim: presentation.text)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(KitColor.text)
            case .off:
                Text(verbatim: presentation.text)
                    .font(.subheadline)
                    .foregroundColor(KitColor.text2)
            case .value:
                Text(verbatim: presentation.text)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(KitColor.text)
            }
        }
        .fixedSize()
    }
}

// MARK: - Chevron

struct KitChevron: View {

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundColor(KitColor.text2)
            .flipsForRightToLeftLayoutDirection(true)
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons

///
/// A 44 pt navigation-bar button. On iOS 26 and later the system draws it;
/// before that it is a `sheet` circle with a `text` icon.
///
struct KitIconButton: View {

    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(action: action) {
                Image(systemName: symbol)
            }
            .accessibilityLabel(Text(verbatim: label))
        } else {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(KitIconButtonStyle())
            .accessibilityLabel(Text(verbatim: label))
        }
    }
}

///
/// The close button: `Button(role: .close)` on iOS 26 and later, `xmark`
/// before. The role exists only in the iOS 26 SDK, so an older Xcode builds
/// the `xmark` button everywhere.
///
struct KitCloseButton: View {

    let action: () -> Void

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
                .accessibilityLabel(Text(verbatim: "Close"))
        } else {
            KitIconButton(symbol: "xmark", label: "Close", action: action)
        }
        #else
        KitIconButton(symbol: "xmark", label: "Close", action: action)
        #endif
    }
}

struct KitIconButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? KitColor.text : KitColor.disabled)
            .background(Circle().fill(KitColor.sheet))
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

/// Body Medium in `action-text`, at least 44 × 44 pt. Only inside content.
struct KitTextButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(isEnabled ? KitColor.actionText : KitColor.disabled)
            .padding(.horizontal, 12)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

///
/// Full width, 56 pt, pill, `action` fill. Pressed, the fill becomes `text`
/// and the label `bg`.
///
struct KitPrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(foreground(isPressed: configuration.isPressed))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(fill(isPressed: configuration.isPressed)))
            .contentShape(Capsule())
    }

    private func fill(isPressed: Bool) -> Color {
        guard isEnabled else { return KitColor.disabledFill }
        return isPressed ? KitColor.text : KitColor.action
    }

    private func foreground(isPressed: Bool) -> Color {
        guard isEnabled else { return KitColor.disabled }
        return isPressed ? KitColor.bg : KitColor.onAction
    }
}

/// A primary button's label: text leading, icon trailing.
struct KitPrimaryButtonLabel: View {

    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: title)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Rows

/// Pressed rows take the `pressed` background.
struct KitRowButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? KitColor.pressed : Color.clear)
            .contentShape(Rectangle())
    }
}

// MARK: - Filter chip

///
/// A 44 pt pill with a 1 pt `field` outline and an optional count in tabular
/// figures. A toggle: it carries the selected trait when on.
///
struct KitChip: View {

    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(verbatim: title)
                if let count {
                    Text(verbatim: "\(count)")
                        .monospacedDigit()
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
        }
        .buttonStyle(KitChipStyle(isSelected: isSelected))
        .accessibilityLabel(Text(verbatim: count.map { "\(title), \($0)" } ?? title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct KitChipStyle: ButtonStyle {

    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? KitColor.onSelected : KitColor.text)
            .background(
                Capsule().fill(background(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : KitColor.field, lineWidth: 1)
            )
            .contentShape(Capsule())
            .opacity(isSelected && configuration.isPressed ? 0.8 : 1)
    }

    private func background(isPressed: Bool) -> Color {
        if isSelected { return KitColor.selected }
        return isPressed ? KitColor.pressed : Color.clear
    }
}

// MARK: - Search field

///
/// A 44 pt pill with a leading magnifier and a clear button once it holds
/// text. Focused, its outline becomes a 2 pt `text` line.
///
struct KitSearchField: View {

    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(KitColor.text2)
                .accessibilityHidden(true)

            TextField(
                "",
                text: $text,
                prompt: Text(verbatim: placeholder).foregroundColor(KitColor.text2)
            )
            .focused($isFocused)
            .font(.body)
            .foregroundColor(KitColor.text)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .accessibilityLabel(Text(verbatim: placeholder))

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(KitColor.text2)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text(verbatim: "Clear search"))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .frame(minHeight: 44)
        .overlay(
            Capsule().strokeBorder(isFocused ? KitColor.text : KitColor.field, lineWidth: isFocused ? 2 : 1)
        )
    }
}
