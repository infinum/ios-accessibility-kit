//
//  KitTool.swift
//  AccessibilityKit
//

import SwiftUI

///
/// Where a tool is listed on the kit home.
///
enum KitToolGroup: CaseIterable {
    case thisDevice
    case thisScreen
    case tryInApp

    var title: String {
        switch self {
        case .thisDevice: return "This device"
        case .thisScreen: return "This screen"
        case .tryInApp: return "Try it in the app"
        }
    }
}

///
/// How a tool runs once it is picked on the kit home.
///
enum KitToolKind {

    /// A screen pushed inside the kit's sheet.
    case screen(@MainActor (KitToolContext) -> AnyView)

    ///
    /// A tool that works on the app itself. The kit closes first and its
    /// button stays hidden until the tool calls `finish`, which returns to
    /// the app rather than to the kit home.
    ///
    case screenTool(@MainActor (_ finish: @escaping @MainActor () -> Void) -> Void)
}

/// What a tool's screen can use.
struct KitToolContext {
    let model: KitModel
}

///
/// One tool of the kit. The kit home is built from the registered tools, so
/// adding one never changes the kit's navigation.
///
@MainActor
protocol KitTool {
    var id: String { get }
    var name: String { get }
    /// The one-line description under the name.
    var summary: String { get }
    var group: KitToolGroup { get }
    /// An SF Symbol name for the tool tile.
    var symbolName: String { get }
    var kind: KitToolKind { get }
}

enum KitToolRegistry {

    /// The tools the kit home lists, in order within their group.
    @MainActor
    static let tools: [any KitTool] = [
        MonitorTool()
    ]
}

// MARK: - Monitor

struct MonitorTool: KitTool {

    let id = "monitor"
    let name = "Monitor"
    let summary = "Which accessibility settings are on, live"
    let group = KitToolGroup.thisDevice
    let symbolName = "slider.horizontal.3"

    var kind: KitToolKind {
        return .screen { context in
            AnyView(MonitorScreen(model: context.model))
        }
    }
}
