//
//  AccessibilityMonitorViewModel.swift
//  AccessibilityKit
//
//  Created by Igor Vatavuk on 08.01.2025..
//

import SwiftUI
import UIKit

///
/// The kit's model of the tracked settings: what the home status line, the
/// Monitor and Feature detail show. One instance lives for as long as the
/// kit is open, so the Monitor's filter and search survive pushes and pops.
///
/// The tracker records the system's own values. The kit shows them with the
/// configured transforms applied, up to the moment the delivered snapshot
/// was taken, so a row's value, its change mark and its history agree.
/// Transforms run for that when a snapshot is delivered, never while views
/// are drawn, and each recorded value is transformed once per configuration.
///
@MainActor
final class AccessibilityMonitorViewModel: ObservableObject {

    // MARK: - Types

    enum Filter: CaseIterable {
        case all
        case on
        case changed

        var title: String {
            switch self {
            case .all: return "All"
            case .on: return "On"
            case .changed: return "Changed"
            }
        }
    }

    enum TrackingStatus: Equatable {
        /// Tracking is not configured, or tracks nothing.
        case notTracked
        /// Tracking follows changes as they happen.
        case live
        /// Tracking read the settings once, at this time.
        case snapshot(Date)
    }

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

    struct Section: Identifiable, Equatable {
        let group: AccessibilityGroup
        let rows: [Row]

        var id: AccessibilityGroup { group }
    }

    /// What the screens show, replaced as a whole on each delivery.
    struct Display: Equatable {
        /// Every tracked setting, grouped and in Settings order.
        var rows = [Row]()
        /// Each setting's history as the app reports it, oldest first:
        /// recorded values through the transform, with values a transform
        /// folds together merged.
        var histories = [String: [AccessibilityHistoryEntry]]()
        var snapshotDate = Date()
    }

    struct HistoryItem: Identifiable, Equatable {
        let id: Int
        let date: Date
        let event: String
    }

    // MARK: - Published properties

    @Published private(set) var states: [AccessibilityState] = []
    @Published private(set) var display = Display()
    @Published private(set) var trackingStatus: TrackingStatus
    @Published var searchText = ""
    @Published var filter: Filter = .all

    // MARK: - Internal properties

    /// Every tracked setting, grouped and in Settings order.
    var allRows: [Row] {
        return display.rows
    }

    /// Set while the Monitor is on screen, so changes are announced there only.
    var isMonitorVisible = false

    // MARK: - Private properties

    /// Held so the tracker lives as long as the screen showing it. The
    /// tracker holds this view model weakly, so there is no cycle.
    private let tracker: AccessibilityTracker
    private let announce: @MainActor (String) -> Void
    private var changeTokens = [String: Int]()
    private var nextChangeToken = 1
    /// Transformed values by identifier and entry sequence, valid for one
    /// configuration, so each recorded value is transformed only once.
    private var transformedValues = [String: [Int: AccessibilityValue]]()
    private var transformedValuesGeneration: Int?

    // MARK: - Lifecycle

    ///
    /// The tracker holds its snapshot observers weakly, so registering is
    /// all this needs: the registration ends when the view model does.
    ///
    init(
        tracker: AccessibilityTracker = .shared,
        announce: @escaping @MainActor (String) -> Void = KitAnnouncer.announcePolitely
    ) {
        self.tracker = tracker
        self.announce = announce
        // Right from the first frame, before the first snapshot lands, so a
        // tracked app never flashes the nothing-tracked screen.
        trackingStatus = Self.trackingStatus(tracker: tracker, date: Date())
        tracker.addSnapshotObserver(self)
    }
}

// MARK: - Rows and sections

extension AccessibilityMonitorViewModel {

    /// The rows the filter and search keep, under their group, empty groups left out.
    var sections: [Section] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let rows = allRows.filter { row in
            matches(row, filter: filter)
                && (query.isEmpty
                    || row.name.localizedCaseInsensitiveContains(query)
                    || row.identifier.localizedCaseInsensitiveContains(query))
        }
        return AccessibilityGroup.allCases.compactMap { group in
            let groupRows = rows.filter { $0.type.group == group }
            return groupRows.isEmpty ? nil : Section(group: group, rows: groupRows)
        }
    }

    /// The filters on offer. Changed needs live tracking.
    var availableFilters: [Filter] {
        return trackingStatus == .live ? Filter.allCases : [.all, .on]
    }

    func count(for filter: Filter) -> Int {
        return allRows.filter { matches($0, filter: filter) }.count
    }

    func row(for identifier: String) -> Row? {
        return allRows.first { $0.identifier == identifier }
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

extension AccessibilityMonitorViewModel {

    var onCount: Int {
        return count(for: .on)
    }

    /// The kit home's status line: "Live · 5 of 21 settings on".
    var homeStatusText: String {
        return statusText(live: "\(onCount) of \(allRows.count) settings on", snapshot: "\(onCount) of \(allRows.count) on")
    }

    /// The Monitor's status line: "Live · 21 tracked · 5 on".
    var monitorStatusText: String {
        let counts = "\(allRows.count) tracked · \(onCount) on"
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

extension AccessibilityMonitorViewModel {

    ///
    /// The snapshot as plain text, one line per setting, plus a JSON file of
    /// its encoded form when it can be written.
    ///
    func shareItems() -> [Any] {
        let text = allRows
            .map { "\($0.name) (\($0.identifier)): \($0.presentation.text)" }
            .joined(separator: "\n")
        var items: [Any] = [text]

        // A folder per share, so a file is never replaced underneath a share
        // sheet still reading it. Only one share sheet is open at a time, so
        // the earlier shares' folders can go.
        let shares = FileManager.default.temporaryDirectory.appendingPathComponent("AccessibilityKit", isDirectory: true)
        try? FileManager.default.removeItem(at: shares)
        let folder = shares.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = folder.appendingPathComponent("accessibility-snapshot.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = AccessibilitySnapshot(states: states, date: display.snapshotDate)
        if let data = try? encoder.encode(snapshot),
           (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)) != nil,
           (try? data.write(to: url, options: .atomic)) != nil {
            items.append(url)
        }
        return items
    }
}

// MARK: - AccessibilitySnapshotObserver

extension AccessibilityMonitorViewModel: AccessibilitySnapshotObserver {

    func accessibilitySnapshotDidChange(_ snapshot: AccessibilitySnapshot, reason: SnapshotDeliveryReason) {
        let previousValues = Dictionary(states.map { ($0.identifier, $0.value) }, uniquingKeysWith: { first, _ in first })
        let status = snapshot.states.isEmpty ? .notTracked : Self.trackingStatus(tracker: tracker, date: snapshot.date)

        // Transforms run below. One that reconfigures tracking makes this
        // snapshot stale: nothing is kept, and the refresh for the new
        // configuration follows.
        let generation = tracker.configurationGeneration
        let transforms = Dictionary(
            tracker.trackingObjects.map { ($0.identifier, $0.transform) },
            uniquingKeysWith: { first, _ in first }
        )
        let sortedStates = snapshot.states.sorted(by: Self.displayOrder)
        let histories = Dictionary(
            sortedStates.map { state in
                let history = displayedHistory(for: state, transform: transforms[state.identifier] ?? nil, upTo: snapshot.historyMark, generation: generation)
                return (state.identifier, history)
            },
            uniquingKeysWith: { first, _ in first }
        )
        guard generation == tracker.configurationGeneration else { return }

        // Only a change the user just made: never a refresh after reconfiguring.
        let changed = reason == .change
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
        if !availableFilters.contains(filter) {
            filter = .all
        }
        display = Display(rows: rows, histories: histories, snapshotDate: snapshot.date)
        states = snapshot.states

        announceChanges(changed)
    }
}

// MARK: - Private methods

private extension AccessibilityMonitorViewModel {

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
    /// A setting's history as the app reports it, up to `mark`: each recorded
    /// value through the setting's transform, and a change kept only when
    /// what the app reports changes, since a transform can fold several
    /// system values into one.
    ///
    func displayedHistory(
        for state: AccessibilityState,
        transform: (@MainActor @Sendable (AccessibilityValue) -> AccessibilityValue)?,
        upTo mark: Int?,
        generation: Int
    ) -> [AccessibilityHistoryEntry] {
        if transformedValuesGeneration != generation {
            transformedValues = [:]
            transformedValuesGeneration = generation
        }
        var known = transformedValues[state.identifier] ?? [:]

        let entries = tracker.history(for: state.type, upTo: mark)
        var displayed = [AccessibilityHistoryEntry]()
        for entry in entries {
            let value: AccessibilityValue
            if let cached = known[entry.sequence] {
                value = cached
            } else {
                value = transform?(entry.value) ?? entry.value
                known[entry.sequence] = value
            }
            guard entry.kind != .change || value != displayed.last?.value else { continue }
            displayed.append(AccessibilityHistoryEntry(sequence: entry.sequence, date: entry.date, value: value, kind: entry.kind))
        }

        // Only what is still recorded is kept, so the cache stays as small as the history.
        let recorded = Set(entries.map(\.sequence))
        transformedValues[state.identifier] = known.filter { recorded.contains($0.key) }
        return displayed
    }

    func matches(_ row: Row, filter: Filter) -> Bool {
        switch filter {
        case .all: return true
        case .on: return row.isOn
        case .changed: return row.changeDate != nil
        }
    }

    static func trackingStatus(tracker: AccessibilityTracker, date: Date) -> TrackingStatus {
        guard tracker.isTracking else { return .notTracked }
        return tracker.fetchType == .continuous ? .live : .snapshot(date)
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

// MARK: - Announcements and dates

enum KitAnnouncer {

    /// Queues an announcement behind whatever VoiceOver is already saying.
    @MainActor
    static func announcePolitely(_ message: String) {
        let announcement = NSAttributedString(
            string: message,
            attributes: [.accessibilitySpeechQueueAnnouncement: true]
        )
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

enum KitDateFormat {

    private static let shortFormatter = KitShared(makeFormatter(timeStyle: .short))
    private static let mediumFormatter = KitShared(makeFormatter(timeStyle: .medium))

    /// "14:02", in the user's locale.
    static func shortTime(_ date: Date) -> String {
        return shortFormatter.value.string(from: date)
    }

    /// "14:02:19", in the user's locale.
    static func mediumTime(_ date: Date) -> String {
        return mediumFormatter.value.string(from: date)
    }

    private static func makeFormatter(timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        // Follows the user's region and 12/24-hour setting as they change.
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = timeStyle
        return formatter
    }
}
