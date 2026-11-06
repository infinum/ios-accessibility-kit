//
//  KitModel.swift
//  AccessibilityKit
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI

///
/// The kit's model of the tracked settings: what the kit home's status
/// line, the Monitor and Feature detail show. One instance lives for as long
/// as the kit is open; the public Monitor view holds one of its own.
///
/// The tracker hands it each feature's value, displayed history and the
/// tracking status, worked out together when the snapshot was taken. It
/// keeps the rows, histories and change marks the screens show and the
/// status lines, and for the Monitor, its change announcements and what it
/// shares. The Monitor's filter and search are the Monitor screen's own, in
/// ``MonitorQuery``.
///
@MainActor
final class KitModel: ObservableObject {

    // MARK: - Types

    struct Row: Identifiable, Equatable {
        let identifier: String
        let type: AccessibilityType
        let value: AccessibilityValue
        let presentation: KitValuePresentation
        let changeDate: Date?
        /// Bumped each time this setting changes while the kit is open, so a
        /// row can mark a change as it happens. Zero until it does.
        let changeToken: Int

        var id: String { identifier }
        var name: String { type.displayName }
        var isOn: Bool { presentation.kind == .on }

        /// "Bold text, on, changed at 14:02". The identifier is left out.
        var accessibilityLabel: String {
            var label = "\(name), \(presentation.spokenText)"
            if let changeDate {
                label += ", changed at \(KitDateFormat.shortTime(changeDate))"
            }
            return label
        }
    }

    ///
    /// What the screens show, and the snapshot it was made from, replaced as
    /// a whole on each delivery.
    ///
    struct Display {
        /// Every tracked setting, grouped and in Settings order.
        var rows = [Row]()
        /// Each setting's history as the app reports it, oldest first:
        /// recorded values through the transform, with values a transform
        /// folds together merged.
        var histories = [String: [AccessibilityHistoryEntry]]()
        /// The snapshot as delivered: what is shared, and what the next
        /// delivery is compared against to spot a change.
        var snapshot = AccessibilitySnapshot(states: [])
    }

    struct HistoryItem: Identifiable, Equatable {
        let id: Int
        let date: Date
        let event: String
    }

    // MARK: - Published properties

    @Published private(set) var display = Display()
    @Published private(set) var trackingStatus: TrackingStatus

    // MARK: - Internal properties

    /// Every tracked setting, grouped and in Settings order.
    var rows: [Row] {
        return display.rows
    }

    /// Set while the Monitor is on screen, so changes are announced there only.
    var isMonitorVisible = false

    // MARK: - Private properties

    /// Held so the tracker lives as long as the screen showing it. The
    /// tracker holds this model weakly, so there is no cycle.
    private let tracker: AccessibilityTracker
    private let announce: @MainActor (String) -> Void
    private var changeTokens = [String: Int]()
    private var nextChangeToken = 1

    // MARK: - Lifecycle

    ///
    /// The tracker holds its listeners weakly, so registering is all this
    /// needs: the registration ends when the model does.
    ///
    init(
        tracker: AccessibilityTracker = .shared,
        announce: @escaping @MainActor (String) -> Void = KitAnnouncer.announcePolitely
    ) {
        self.tracker = tracker
        self.announce = announce
        // Right from the first frame, before the first update lands, so a
        // tracked app never flashes the nothing-tracked screen.
        trackingStatus = tracker.trackingStatus
        tracker.addListener(self)
    }
}

// MARK: - Rows

extension KitModel {

    func row(for identifier: String) -> Row? {
        return rows.first { $0.identifier == identifier }
    }

    /// This session's values for a setting, newest first.
    func history(for identifier: String) -> [HistoryItem] {
        guard let type = row(for: identifier)?.type else { return [] }

        return (display.histories[identifier] ?? []).reversed().map { entry in
            HistoryItem(id: entry.sequence, date: entry.date, event: Self.event(for: entry.kind, value: entry.value, type: type))
        }
    }
}

// MARK: - Status lines

extension KitModel {

    var onCount: Int {
        return rows.filter(\.isOn).count
    }

    /// The kit home's status line: "Live · 5 of 21 settings on".
    var homeStatusText: String {
        return statusText(live: "\(onCount) of \(rows.count) settings on", snapshot: "\(onCount) of \(rows.count) on")
    }

    /// The Monitor's status line: "Live · 21 tracked · 5 on".
    var monitorStatusText: String {
        let counts = "\(rows.count) tracked · \(onCount) on"
        return statusText(live: counts, snapshot: counts)
    }

    private func statusText(live: String, snapshot: String) -> String {
        switch trackingStatus {
        case .notTracked:
            return "Tracking not set up"
        case .live:
            return "Live · \(live)"
        case .snapshot(let date):
            return "Snapshot at \(KitDateFormat.shortTime(date)) · \(snapshot)"
        }
    }
}

// MARK: - Sharing

extension KitModel {

    /// The snapshot as plain text, one line per setting.
    var shareText: String {
        return rows
            .map { "\($0.name) (\($0.identifier)): \($0.presentation.text)" }
            .joined(separator: "\n")
    }

    ///
    /// The snapshot as plain text, plus a JSON file of its encoded form when
    /// it can be written.
    ///
    func shareItems() -> [Any] {
        var items: [Any] = [shareText]

        // A folder per share, so a file is never replaced underneath a share
        // sheet still reading it. Only one share sheet is open at a time, so
        // the earlier shares' folders can go.
        let shares = FileManager.default.temporaryDirectory.appendingPathComponent("AccessibilityKit", isDirectory: true)
        try? FileManager.default.removeItem(at: shares)
        let folder = shares.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = folder.appendingPathComponent("accessibility-snapshot.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(display.snapshot),
           (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)) != nil,
           (try? data.write(to: url, options: .atomic)) != nil {
            items.append(url)
        }
        return items
    }
}

// MARK: - TrackerListener

extension KitModel: TrackerListener {

    func trackerDidUpdate(_ update: TrackerUpdate) {
        let snapshot = update.snapshot
        let status = update.status
        let histories = update.histories
        let previousValues = Dictionary(display.snapshot.states.map { ($0.identifier, $0.value) }, uniquingKeysWith: { first, _ in first })
        let sortedStates = snapshot.states.sorted(by: Self.displayOrder)

        // Only a change the user just made: never a refresh after reconfiguring.
        let changed = update.reason == .change
            ? sortedStates.filter { state in previousValues[state.identifier].map { $0 != state.value } ?? false }
            : []
        for state in changed {
            changeTokens[state.identifier] = nextChangeToken
            nextChangeToken += 1
        }

        let rows = sortedStates.map { state in
            Row(
                identifier: state.identifier,
                type: state.type,
                value: state.value,
                presentation: KitValuePresentation(value: state.value, type: state.type),
                changeDate: status == .live ? histories[state.identifier]?.last(where: { $0.kind == .change })?.date : nil,
                changeToken: changeTokens[state.identifier] ?? 0
            )
        }

        trackingStatus = status
        display = Display(rows: rows, histories: histories, snapshot: snapshot)

        announceChanges(changed)
    }
}

// MARK: - Private methods

private extension KitModel {

    static func displayOrder(_ lhs: AccessibilityState, _ rhs: AccessibilityState) -> Bool {
        if lhs.type.displayIndex != rhs.type.displayIndex {
            return lhs.type.displayIndex < rhs.type.displayIndex
        }
        return lhs.identifier < rhs.identifier
    }

    static func event(for kind: AccessibilityHistoryEntry.Kind, value: AccessibilityValue, type: AccessibilityType) -> String {
        let presentation = KitValuePresentation(value: value, type: type)
        switch (kind, presentation.kind) {
        case (.launch, _):
            return "\(presentation.text) at launch"
        case (.start, _):
            return "\(presentation.text) when tracking started"
        case (.change, .on):
            return "Turned on"
        case (.change, .off):
            return "Turned off"
        case (.change, .value):
            return "Changed to \(presentation.text)"
        }
    }

    ///
    /// "Bold text turned on", queued behind whatever VoiceOver is saying.
    /// Only while the Monitor is on screen.
    ///
    func announceChanges(_ changed: [AccessibilityState]) {
        guard isMonitorVisible else { return }

        for state in changed {
            let presentation = KitValuePresentation(value: state.value, type: state.type)
            switch presentation.kind {
            case .on, .off:
                announce("\(state.type.displayName) turned \(presentation.spokenText)")
            case .value:
                announce("\(state.type.displayName), \(presentation.spokenText)")
            }
        }
    }
}
