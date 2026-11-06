//
//  MonitorQueryTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@Suite("MonitorQuery")
@MainActor
struct MonitorQueryTests {

    ///
    /// Groups follow Settings: Vision before Motion, and no Hearing,
    /// Interaction or Spoken content sections for features nobody tracks.
    /// The rows keep the order they are given, which the kit's model has
    /// already put in Settings order.
    ///
    @Test("Groups rows into sections in Settings order, leaving empty groups out")
    func groupsRowsIntoSections() {
        let sections = MonitorQuery().sections(of: Self.rows, status: .live)

        #expect(sections.map(\.group) == [.vision, .motion])
        #expect(sections.first?.rows.map(\.type) == [.voiceOver, .boldText])
    }

    @Test("Keeps only the rows that are on, or that changed, under those filters")
    func filtersByOnAndChanged() {
        var query = MonitorQuery()

        query.filter = .on
        #expect(Self.types(in: query.sections(of: Self.rows, status: .live)) == [.boldText])

        query.filter = .changed
        #expect(Self.types(in: query.sections(of: Self.rows, status: .live)) == [.reduceMotion])
    }

    @Test("Searches names and identifiers, ignoring case and surrounding spaces")
    func searchesNamesAndIdentifiers() {
        var query = MonitorQuery()

        query.searchText = "REDUCE_"
        #expect(Self.types(in: query.sections(of: Self.rows, status: .live)) == [.reduceMotion])

        query.searchText = "  voice "
        #expect(Self.types(in: query.sections(of: Self.rows, status: .live)) == [.voiceOver])

        query.searchText = "nothing like this"
        #expect(query.sections(of: Self.rows, status: .live).isEmpty)
    }

    ///
    /// A one-time snapshot has no changes to show, so Changed is not offered.
    ///
    @Test("Offers the Changed filter only while tracking is live")
    func offersChangedOnlyWhileLive() {
        #expect(MonitorQuery.availableFilters(for: .live) == [.all, .on, .changed])
        #expect(MonitorQuery.availableFilters(for: .snapshot(Date())) == [.all, .on])
    }

    ///
    /// Changed was chosen while tracking was live, and tracking was then
    /// reconfigured to a one-time snapshot. The Monitor shows All, and the
    /// choice comes back if tracking goes live again.
    ///
    @Test("Shows every row while the chosen filter is not on offer, keeping the choice")
    func fallsBackToAllWhileTheChoiceIsNotOffered() {
        var query = MonitorQuery()
        query.filter = .changed
        let snapshot = TrackingStatus.snapshot(Date())

        #expect(query.effectiveFilter(for: snapshot) == .all)
        #expect(Self.types(in: query.sections(of: Self.rows, status: snapshot)) == [.voiceOver, .boldText, .reduceMotion])
        #expect(query.effectiveFilter(for: .live) == .changed)
    }

    ///
    /// The chips count every row: the search does not narrow them.
    ///
    @Test("Counts each filter's rows among every row")
    func countsEachFiltersRows() {
        #expect(MonitorQuery.Filter.all.count(in: Self.rows) == 3)
        #expect(MonitorQuery.Filter.on.count(in: Self.rows) == 1)
        #expect(MonitorQuery.Filter.changed.count(in: Self.rows) == 1)
    }
}

// MARK: - Rows

private extension MonitorQueryTests {

    ///
    /// VoiceOver off, Bold text on, Reduce motion off and changed this
    /// session, in Settings order as the kit's model hands them over.
    ///
    static let rows = [
        row(.voiceOver),
        row(.boldText, isOn: true),
        row(.reduceMotion, changeDate: Date())
    ]

    static func types(in sections: [MonitorQuery.Section]) -> [AccessibilityType] {
        return sections.flatMap(\.rows).map(\.type)
    }

    static func row(_ type: AccessibilityType, isOn: Bool = false, changeDate: Date? = nil) -> KitModel.Row {
        let value = AccessibilityValue.flag(isOn)
        return KitModel.Row(
            identifier: type.rawValue,
            type: type,
            value: value,
            presentation: KitValuePresentation(value: value, type: type),
            changeDate: changeDate,
            changeToken: 0
        )
    }
}
