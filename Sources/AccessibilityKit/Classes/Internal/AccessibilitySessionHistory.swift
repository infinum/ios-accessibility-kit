//
//  AccessibilitySessionHistory.swift
//  AccessibilityKit
//

import Foundation

///
/// One recorded value of a tracked feature, as the system reported it,
/// before any transform.
///
struct AccessibilityHistoryEntry: Equatable, Sendable {

    enum Kind: Equatable, Sendable {
        /// The value when tracking started, at the app's launch.
        case launch
        /// The value when tracking started for the feature later on.
        case start
        /// A value that differs from the one before it.
        case change
    }

    /// Unique within the session and never reused, so a list can key on it.
    let sequence: Int
    let date: Date
    let value: AccessibilityValue
    let kind: Kind
}

///
/// What each tracked feature has reported this session, per feature type.
///
/// It holds the system's own values: the states the tracker reads on every
/// notification anyway, so recording runs no app code. Transforms belong to
/// whoever displays the history, which keeps it valid across
/// reconfigurations that change them.
///
/// The value a feature started with is always kept. After it, only the
/// newest changes are kept, so a feature toggled many times holds at most
/// ``maximumEntryCount`` entries in all.
///
struct AccessibilitySessionHistory: Sendable {

    static let maximumEntryCount = 50

    private var entries = [AccessibilityType: [AccessibilityHistoryEntry]]()
    private var nextSequence = 0
    private var hasStarted = false

    ///
    /// Moves to the features a configuration tracks, read as `states`:
    /// features no longer tracked are dropped, features still tracked keep
    /// their history, and new ones start here — at launch only for the first
    /// configuration, and only when it comes `atLaunch`.
    ///
    mutating func track(_ states: [AccessibilityState], at date: Date, atLaunch: Bool = true) {
        let tracked = Set(states.map(\.type))
        entries = entries.filter { tracked.contains($0.key) }

        let startKind: AccessibilityHistoryEntry.Kind = !hasStarted && atLaunch ? .launch : .start
        // A first configuration with nothing in it has not started anything.
        hasStarted = hasStarted || !states.isEmpty
        for state in states {
            if entries[state.type] == nil {
                entries[state.type] = [makeEntry(date: date, value: state.value, kind: startKind)]
            } else {
                record(state, at: date)
            }
        }
    }

    ///
    /// Records a feature's value if it differs from the last one recorded.
    /// A feature that is not tracked is ignored.
    ///
    mutating func record(_ state: AccessibilityState, at date: Date) {
        guard var featureEntries = entries[state.type], let last = featureEntries.last, last.value != state.value else { return }

        featureEntries.append(makeEntry(date: date, value: state.value, kind: .change))
        if featureEntries.count > Self.maximumEntryCount {
            // The start entry stays; the oldest change goes.
            featureEntries.remove(at: 1)
        }
        entries[state.type] = featureEntries
    }

    /// Everything recorded for a feature, oldest first.
    func entries(for type: AccessibilityType) -> [AccessibilityHistoryEntry] {
        return entries[type] ?? []
    }

    private mutating func makeEntry(date: Date, value: AccessibilityValue, kind: AccessibilityHistoryEntry.Kind) -> AccessibilityHistoryEntry {
        defer { nextSequence += 1 }
        return AccessibilityHistoryEntry(sequence: nextSequence, date: date, value: value, kind: kind)
    }
}
