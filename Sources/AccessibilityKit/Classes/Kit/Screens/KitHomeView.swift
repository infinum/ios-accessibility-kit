//
//  KitHomeView.swift
//  AccessibilityKit
//

import SwiftUI

///
/// The kit's sheet: a navigation stack whose root is the kit home.
///
struct KitRootView: View {

    @ObservedObject var model: AccessibilityMonitorViewModel
    let tools: [any KitTool]
    let close: () -> Void
    let startScreenTool: (KitToolKind) -> Void

    var body: some View {
        KitNavigationContainer {
            KitHomeView(model: model, tools: tools, close: close, startScreenTool: startScreenTool)
        }
        .tint(KitColor.text)
    }
}

///
/// The kit home: the status of tracking, then the registered tools under
/// their groups. A group with no tools is left out, and the kit always opens
/// here, even with one tool, so adding a tool never changes navigation.
///
struct KitHomeView: View {

    @ObservedObject var model: AccessibilityMonitorViewModel
    let tools: [any KitTool]
    let close: () -> Void
    let startScreenTool: (KitToolKind) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let title = "Accessibility Kit"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if dynamicTypeSize.isAccessibilitySize {
                    KitContentTitle(title: Self.title)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }

                KitStatusLine(text: model.homeStatusText, status: model.trackingStatus)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                ForEach(KitToolGroup.allCases, id: \.self) { group in
                    let groupTools = tools.filter { $0.group == group }
                    if !groupTools.isEmpty {
                        KitSectionHeader(title: group.title)
                        ForEach(groupTools, id: \.id) { tool in
                            toolRow(for: tool)
                        }
                    }
                }
            }
            .padding(.bottom, 36)
            .kitReadableWidth()
        }
        .background(KitColor.bg.ignoresSafeArea())
        // At accessibility sizes the title wraps in the content instead of
        // being cut off in the bar.
        .navigationTitle(Text(verbatim: dynamicTypeSize.isAccessibilitySize ? "" : Self.title))
        .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                KitCloseButton(action: close)
            }
        }
    }

    @ViewBuilder
    private func toolRow(for tool: any KitTool) -> some View {
        let label = KitToolRow(tool: tool, showsTile: !dynamicTypeSize.isAccessibilitySize)
        switch tool.kind {
        case .screen(let makeScreen):
            NavigationLink(destination: makeScreen(KitToolContext(model: model))) { label }
                .buttonStyle(KitRowButtonStyle())
                .accessibilityLabel(Text(verbatim: "\(tool.name). \(tool.summary)"))
        case .screenTool:
            Button { startScreenTool(tool.kind) } label: { label }
                .buttonStyle(KitRowButtonStyle())
                .accessibilityLabel(Text(verbatim: "\(tool.name). \(tool.summary)"))
        }
    }
}

///
/// The status line under a title: a live dot and "Live · …", a hollow dot
/// for a one-time snapshot, no dot when nothing is tracked.
///
struct KitStatusLine: View {

    let text: String
    let status: TrackingStatus

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            switch status {
            case .live:
                KitLiveDot()
                    .alignmentGuide(.firstTextBaseline, computeValue: Self.centreOnFirstLine)
            case .snapshot:
                KitLiveDot(isHollow: true)
                    .alignmentGuide(.firstTextBaseline, computeValue: Self.centreOnFirstLine)
            case .notTracked:
                EmptyView()
            }
            Text(verbatim: text)
                .font(.subheadline)
                .foregroundColor(KitColor.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    ///
    /// Sits the dot on the middle of the first line's capitals rather than
    /// the middle of a wrapped status. The dot scales with the text, and
    /// raising its bottom a third of its height above the baseline lands it
    /// there.
    ///
    private nonisolated static func centreOnFirstLine(_ dimensions: ViewDimensions) -> CGFloat {
        return dimensions[.bottom] + dimensions.height / 3
    }
}

///
/// 72 pt minimum: a 36 pt tile with the tool's symbol, its name and a
/// one-line description, and a chevron. At accessibility sizes the tile
/// gives its width to the text.
///
struct KitToolRow: View {

    let tool: any KitTool
    let showsTile: Bool

    var body: some View {
        HStack(spacing: 12) {
            if showsTile {
                Image(systemName: tool.symbolName)
                    .font(.system(size: 20))
                    .foregroundColor(KitColor.text)
                    .frame(width: 36, height: 36)
                    .background(KitColor.sheet)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: tool.name)
                    .font(.body)
                    .foregroundColor(KitColor.text)
                Text(verbatim: tool.summary)
                    .font(.footnote)
                    .foregroundColor(KitColor.text2)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            KitChevron()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 72)
        .kitTopRule(leadingInset: 20)
    }
}
