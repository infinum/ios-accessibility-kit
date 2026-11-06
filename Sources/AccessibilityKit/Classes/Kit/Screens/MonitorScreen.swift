//
//  MonitorScreen.swift
//  AccessibilityKit
//

import SwiftUI
import UIKit

///
/// Which accessibility settings are on: searchable, filterable, grouped as
/// in Settings, each row pushing its Feature detail.
///
struct MonitorScreen: View {

    @ObservedObject var model: AccessibilityMonitorViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var shareAnchor = KitPresentationAnchor()

    var body: some View {
        // A container that stays put while its content switches, so appear
        // and disappear below fire once for the screen, not for each child.
        ZStack {
            if model.trackingStatus == .notTracked {
                NothingTrackedView()
            } else {
                list
            }
        }
        .background(KitColor.bg.ignoresSafeArea())
        .navigationTitle(Text(verbatim: "Monitor"))
        .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if model.trackingStatus != .notTracked {
                    KitIconButton(symbol: "square.and.arrow.up", label: "Share snapshot") {
                        shareAnchor.present(UIActivityViewController(activityItems: model.shareItems(), applicationActivities: nil))
                    }
                    .background(KitPresentationAnchorView(anchor: shareAnchor))
                }
            }
        }
        .onAppear { model.isMonitorVisible = true }
        .onDisappear { model.isMonitorVisible = false }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                KitStatusLine(text: model.monitorStatusText, status: model.trackingStatus)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                controls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                let sections = model.sections
                if sections.isEmpty, !model.allRows.isEmpty {
                    Text(verbatim: "Nothing matches this filter yet.")
                        .font(.body)
                        .foregroundColor(KitColor.text2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 36)
                } else {
                    ForEach(sections) { section in
                        KitSectionHeader(title: section.group.displayName)
                        ForEach(section.rows) { row in
                            NavigationLink(destination: FeatureDetailView(model: model, identifier: row.identifier)) {
                                KitFeatureRow(row: row, isStacked: dynamicTypeSize.isAccessibilitySize)
                            }
                            .buttonStyle(KitRowButtonStyle())
                            .accessibilityLabel(Text(verbatim: row.accessibilityLabel))
                        }
                    }
                }
            }
            .padding(.bottom, 36)
            .kitReadableWidth()
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            if case .snapshot(let date) = model.trackingStatus {
                Text(verbatim: "This list shows the settings at \(KitDateFormat.shortTime(date)). Turn on continuous tracking to see changes as they happen.")
                    .font(.footnote)
                    .foregroundColor(KitColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KitColor.sheet)
            }

            KitSearchField(placeholder: "Search features", text: $model.searchText)

            chips
        }
    }

    @ViewBuilder
    private var chips: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayoutStack.vertical
            : AnyLayoutStack.horizontal
        layout.stack {
            ForEach(model.availableFilters, id: \.self) { filter in
                KitChip(
                    title: filter.title,
                    count: model.count(for: filter),
                    isSelected: model.filter == filter
                ) {
                    model.filter = filter
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: "Filter"))
    }
}

/// Chips sit in a row, or in a column at accessibility text sizes.
private enum AnyLayoutStack {
    case horizontal
    case vertical

    @ViewBuilder
    func stack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        switch self {
        case .horizontal:
            HStack(spacing: 8, content: content)
        case .vertical:
            VStack(alignment: .leading, spacing: 8, content: content)
        }
    }
}

// MARK: - Feature row

///
/// 64 pt minimum: the name, the identifier in mono, an optional "Changed at"
/// line, then the status and a chevron. At accessibility sizes it stacks.
/// A change while it is on screen fades a `sheet` background in and out.
///
struct KitFeatureRow: View {

    let row: AccessibilityMonitorViewModel.Row
    let isStacked: Bool

    @State private var isHighlighted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if isStacked {
                VStack(alignment: .leading, spacing: 8) {
                    name
                    KitStatusView(presentation: row.presentation)
                    identifier
                    changeLine
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        name
                        identifier
                        changeLine
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    KitStatusView(presentation: row.presentation)
                    KitChevron()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
        .background(isHighlighted ? KitColor.sheet : Color.clear)
        .kitTopRule(leadingInset: 20)
        // The model bumps the token only for a change the user just made,
        // never for a refresh, so only that flashes the row.
        .onChange(of: row.changeToken) { token in
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.3)) { isHighlighted = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // A later change has its own fade-out.
                guard token == row.changeToken else { return }
                withAnimation(.easeOut(duration: 0.9)) { isHighlighted = false }
            }
        }
    }

    private var name: some View {
        Text(verbatim: row.name)
            .font(.body)
            .foregroundColor(KitColor.text)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var identifier: some View {
        Text(verbatim: row.identifier)
            .font(.caption.monospaced())
            .foregroundColor(KitColor.text2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var changeLine: some View {
        if let changeDate = row.changeDate {
            HStack(spacing: 8) {
                KitLiveDot()
                Text(verbatim: "Changed at \(KitDateFormat.shortTime(changeDate))")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(KitColor.text)
            }
        }
    }
}

// MARK: - Nothing tracked

///
/// Shown when the Monitor opens before tracking is configured, or with no
/// features to track.
///
struct NothingTrackedView: View {

    static let setupGuideURL = URL(string: "https://github.com/infinum/ios-accessibility-kit#usage")!

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: "Nothing is tracked yet")
                        .font(.title.bold())
                        .foregroundColor(KitColor.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: "The Monitor lists features once AccessibilityKit tracks them. Configure tracking at launch, and this list fills in by itself.")
                        .font(.body)
                        .foregroundColor(KitColor.text2)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)
                .kitTopRule()

                Button {
                    openURL(Self.setupGuideURL)
                } label: {
                    KitPrimaryButtonLabel(title: "Open setup guide", symbol: "arrow.up.right.square")
                }
                .buttonStyle(KitPrimaryButtonStyle())
                .accessibilityLabel(Text(verbatim: "Open setup guide, opens in Safari"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .kitReadableWidth()
        }
    }
}

// MARK: - Presenting UIKit controllers

///
/// Finds the view controller to present a UIKit controller from — the share
/// sheet — from wherever its anchor view sits, the kit's sheet or an app's.
///
@MainActor
final class KitPresentationAnchor {

    weak var view: UIView?

    func present(_ controller: UIViewController) {
        // The anchor's own window, or failing that the key window: the kit
        // makes its window key while it is open.
        guard let window = view?.window ?? KitCoordinator.keyWindow(),
              let presenter = window.rootViewController?.kitTopmostPresented else { return }
        if let popover = controller.popoverPresentationController {
            if let view, view.window != nil {
                popover.sourceView = view
                popover.sourceRect = view.bounds
            } else {
                popover.sourceView = presenter.view
                popover.sourceRect = CGRect(x: presenter.view.bounds.maxX - 44, y: presenter.view.safeAreaInsets.top, width: 44, height: 44)
            }
        }
        presenter.present(controller, animated: true)
    }
}

struct KitPresentationAnchorView: UIViewRepresentable {

    let anchor: KitPresentationAnchor

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        anchor.view = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        anchor.view = uiView
    }
}
