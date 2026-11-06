//
//  MonitorQuery.swift
//  AccessibilityKit
//

import Foundation

///
/// What the Monitor's filter and search keep of the kit's rows. The Monitor
/// screen owns it, so it lasts while the Monitor is in the navigation stack,
/// Feature detail included, and starts over when the Monitor is left for
/// the kit home.
///
struct MonitorQuery {

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

        func matches(_ row: KitModel.Row) -> Bool {
            switch self {
            case .all: return true
            case .on: return row.isOn
            case .changed: return row.changeDate != nil
            }
        }

        func count(in rows: [KitModel.Row]) -> Int {
            return rows.filter(matches).count
        }
    }

    struct Section: Identifiable {
        let group: AccessibilityGroup
        let rows: [KitModel.Row]

        var id: AccessibilityGroup { group }
    }

    // MARK: - Internal properties

    var filter: Filter = .all
    var searchText = ""

    // MARK: - Internal methods

    /// The filters on offer. Changed needs live tracking.
    static func availableFilters(for status: TrackingStatus) -> [Filter] {
        return status == .live ? Filter.allCases : [.all, .on]
    }

    ///
    /// The filter in effect: the chosen one while it is on offer, All
    /// otherwise. The choice itself is kept, so it comes back when it is
    /// offered again.
    ///
    func effectiveFilter(for status: TrackingStatus) -> Filter {
        return Self.availableFilters(for: status).contains(filter) ? filter : .all
    }

    ///
    /// The rows the filter in effect and the search keep, under their group,
    /// in the order they are given, empty groups left out.
    ///
    func sections(of rows: [KitModel.Row], status: TrackingStatus) -> [Section] {
        let applied = effectiveFilter(for: status)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = rows.filter { row in
            applied.matches(row)
                && (query.isEmpty
                    || row.name.localizedCaseInsensitiveContains(query)
                    || row.identifier.localizedCaseInsensitiveContains(query))
        }
        return AccessibilityGroup.allCases.compactMap { group in
            let groupRows = kept.filter { $0.type.group == group }
            return groupRows.isEmpty ? nil : Section(group: group, rows: groupRows)
        }
    }
}
