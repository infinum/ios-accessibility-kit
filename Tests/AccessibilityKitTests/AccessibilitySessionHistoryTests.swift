//
//  AccessibilitySessionHistoryTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
@testable import AccessibilityKit

@Suite("AccessibilitySessionHistory")
struct AccessibilitySessionHistoryTests {

    @Test("Starts every feature at launch with its value then")
    func startsEveryFeatureAtLaunch() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(true))], at: Self.date(0))

        #expect(history.entries(for: .voiceOver) == [
            AccessibilityHistoryEntry(sequence: 0, date: Self.date(0), value: .flag(true), kind: .launch)
        ])
    }

    @Test("Records a change, and only a change")
    func recordsOnlyChanges() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(false))], at: Self.date(0))
        history.record(Self.voiceOver(.flag(false)), at: Self.date(1))
        history.record(Self.voiceOver(.flag(true)), at: Self.date(2))

        #expect(history.entries(for: .voiceOver).map(\.value) == [.flag(false), .flag(true)])
        #expect(history.entries(for: .voiceOver).last?.kind == .change)
    }

    @Test("Ignores a feature that is not tracked")
    func ignoresUntrackedFeatures() {
        var history = AccessibilitySessionHistory()
        history.record(Self.voiceOver(.flag(true)), at: Self.date(5))

        #expect(history.entries(for: .voiceOver).isEmpty)
    }

    ///
    /// A setting toggled all session long must not grow without bound, but
    /// the value it started with is what the newest changes are read
    /// against, so it is never the one dropped.
    ///
    @Test("Keeps the start and the newest changes, 50 entries in all")
    func keepsTheStartAndTheNewestChanges() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(false))], at: Self.date(0))
        for second in 1...120 {
            history.record(Self.voiceOver(.flag(second.isMultiple(of: 2) == false)), at: Self.date(TimeInterval(second)))
        }

        let entries = history.entries(for: .voiceOver)
        #expect(entries.count == AccessibilitySessionHistory.maximumEntryCount)
        #expect(entries.first?.kind == .launch)
        #expect(entries.first?.date == Self.date(0))
        #expect(entries.last?.date == Self.date(120))
        #expect(entries[1].date == Self.date(72))
        // Lists key on the sequence, so dropping old entries must not renumber the rest.
        #expect(entries.map(\.sequence) == [0] + Array(72...120))
    }

    @Test("Keeps the history of features a new configuration still tracks")
    func keepsHistoryAcrossConfigurations() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(false))], at: Self.date(0))
        history.record(Self.voiceOver(.flag(true)), at: Self.date(1))
        history.track([Self.voiceOver(.flag(true))], at: Self.date(2))

        #expect(history.entries(for: .voiceOver).map(\.kind) == [.launch, .change])
    }

    ///
    /// A feature added by a later configuration was not tracked at launch,
    /// so its first entry must not claim to be from then.
    ///
    @Test("Starts a feature a later configuration adds where it is added")
    func startsAFeatureAddedLater() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(false))], at: Self.date(0))
        history.track([Self.voiceOver(.flag(false)), Self.boldText(.flag(true))], at: Self.date(1))

        #expect(history.entries(for: .voiceOver).map(\.kind) == [.launch])
        #expect(history.entries(for: .boldText).map(\.kind) == [.start])
    }

    @Test("Starts at launch with the first configuration that tracks something")
    func startsAtLaunchWithTheFirstNonEmptyConfiguration() {
        var history = AccessibilitySessionHistory()
        history.track([], at: Self.date(0))
        history.track([Self.voiceOver(.flag(false))], at: Self.date(1))

        #expect(history.entries(for: .voiceOver).map(\.kind) == [.launch])
    }

    ///
    /// An app may configure tracking after sign-in, minutes into the session.
    /// Its first values are not from launch, so they must not say so.
    ///
    @Test("Starts after launch when tracking is first configured later")
    func startsAfterLaunchWhenConfiguredLater() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(false))], at: Self.date(600), atLaunch: false)

        #expect(history.entries(for: .voiceOver).map(\.kind) == [.start])
    }

    @Test("Drops the history of features a new configuration no longer tracks")
    func dropsHistoryOfUntrackedFeatures() {
        var history = AccessibilitySessionHistory()
        history.track([Self.voiceOver(.flag(false))], at: Self.date(0))
        history.track([Self.boldText(.flag(true))], at: Self.date(1))

        #expect(history.entries(for: .voiceOver).isEmpty)
        #expect(history.entries(for: .boldText).map(\.kind) == [.start])
    }

    private static func voiceOver(_ value: AccessibilityValue) -> AccessibilityState {
        return AccessibilityState(type: .voiceOver, name: "VoiceOver", value: value)
    }

    private static func boldText(_ value: AccessibilityValue) -> AccessibilityState {
        return AccessibilityState(type: .boldText, name: "Bold text", value: value)
    }

    private static func date(_ seconds: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: seconds)
    }
}
