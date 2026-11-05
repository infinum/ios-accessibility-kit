//
//  KitModelTests.swift
//  AccessibilityKitTests
//

import Foundation
import Testing
import UIKit
@testable import AccessibilityKit

@Suite("AccessibilityType metadata")
@MainActor
struct AccessibilityTypeMetadataTests {

    @Test("Lists every feature exactly once in Settings order")
    func listsEveryFeatureOnce() {
        #expect(Set(AccessibilityType.displayOrder) == Set(AccessibilityType.allCases))
        #expect(AccessibilityType.displayOrder.count == AccessibilityType.allCases.count)
    }

    ///
    /// The Monitor lists sections in group order and rows in display order,
    /// so a group's features must sit together in the display order.
    ///
    @Test("Keeps each group's features together, in group order")
    func keepsGroupsTogether() {
        let groups = AccessibilityType.displayOrder.map(\.group)
        let runs = groups.reduce(into: [AccessibilityGroup]()) { runs, group in
            if runs.last != group { runs.append(group) }
        }
        #expect(runs == AccessibilityGroup.allCases)
    }

    @Test("Names features in sentence case for display")
    func namesFeatures() {
        #expect(AccessibilityType.boldText.displayName == "Bold text")
        #expect(AccessibilityType.voiceOver.displayName == "VoiceOver")
        #expect(AccessibilityType.crossFadeTransitions.displayName == "Cross-fade transitions")
        #expect(AccessibilityGroup.spokenContent.displayName == "Spoken content")
    }

    @Test("Reports the notification tracking listens to", arguments: AccessibilityType.allCases)
    func reportsTheNotification(type: AccessibilityType) {
        #expect(type.notificationName == AccessibilityObjectFactory.object(for: type).notificationName)
    }
}

@Suite("KitValuePresentation")
struct KitValuePresentationTests {

    @Test("Shows flags as On and Off, spoken in lower case")
    func showsFlags() {
        let on = KitValuePresentation(value: .flag(true), type: .boldText)
        let off = KitValuePresentation(value: .flag(false), type: .boldText)

        #expect(on.kind == .on && on.text == "On" && on.spokenText == "on")
        #expect(off.kind == .off && off.text == "Off" && off.spokenText == "off")
    }

    @Test("Names the text size a font scale stands for")
    func namesTheTextSize() {
        let presentation = KitValuePresentation(value: .scale(19.0 / 17), type: .fontScale)

        #expect(presentation.kind == .value)
        #expect(presentation.text.hasSuffix("× · XL"))
        #expect(presentation.spokenText.hasSuffix(" times, XL"))
    }

    @Test("Leaves the size out of a scale that is not a font scale")
    func leavesTheSizeOutOfOtherScales() {
        let presentation = KitValuePresentation(value: .scale(2), type: .boldText)

        #expect(!presentation.text.contains("·"))
    }

    @Test("Finds the nearest of the twelve text sizes")
    func findsTheNearestTextSize() {
        #expect(BodyTextSize.nearest(toScale: 1)?.shortName == "L")
        #expect(BodyTextSize.nearest(toScale: 2.35)?.shortName == "AX3")
        #expect(BodyTextSize.nearest(toScale: 0.82)?.shortName == "XS")
        #expect(BodyTextSize.nearest(toScale: 0.5) == nil)
        #expect(BodyTextSize.nearest(toScale: 10) == nil)
        #expect(BodyTextSize.nearest(toScale: .nan) == nil)
    }
}

@Suite("AccessibilityMonitorViewModel for the kit")
@MainActor
struct KitViewModelTests {

    ///
    /// The view model is created as the kit opens and its first snapshot
    /// lands a turn later. A tracked app must not flash the nothing-tracked
    /// screen in between.
    ///
    @Test("Reports live tracking from the start, before the first snapshot lands")
    func reportsLiveTrackingFromTheStart() throws {
        let fixture = try Fixture(fetchType: .continuous)

        #expect(fixture.viewModel.trackingStatus == .live)
        #expect(fixture.viewModel.allRows.isEmpty)
    }

    @Test("Reports nothing tracked before tracking is configured")
    func reportsNothingTracked() async {
        let viewModel = AccessibilityMonitorViewModel(monitor: AccessibilityMonitor(notificationCenter: NotificationCenter()))
        await settle()

        #expect(viewModel.trackingStatus == .notTracked)
        #expect(viewModel.homeStatusText == "Tracking not set up")
    }

    @Test("Reports nothing tracked when tracking is configured with no features")
    func reportsNothingTrackedForAnEmptyConfiguration() async throws {
        let monitor = AccessibilityMonitor(notificationCenter: NotificationCenter())
        monitor.configureAccessibilityTracking(with: try AccessibilityTrackingConfiguration(fetchType: .continuous, objects: []))
        let viewModel = AccessibilityMonitorViewModel(monitor: monitor)
        await settle()

        #expect(viewModel.trackingStatus == .notTracked)
        #expect(viewModel.monitorStatusText == "Tracking not set up")
    }

    @Test("Reports live tracking with its counts")
    func reportsLiveTracking() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })

        #expect(fixture.viewModel.trackingStatus == .live)
        #expect(fixture.viewModel.homeStatusText == "Live · 1 of 3 settings on")
        #expect(fixture.viewModel.monitorStatusText == "Live · 3 tracked · 1 on")
        #expect(fixture.viewModel.availableFilters == [.all, .on, .changed])
    }

    @Test("Reports a one-time snapshot, without the Changed filter")
    func reportsASnapshot() async throws {
        let fixture = try Fixture(fetchType: .initial)
        await poll(until: { !fixture.viewModel.states.isEmpty })

        guard case .snapshot = fixture.viewModel.trackingStatus else {
            Issue.record("Expected a snapshot status, got \(fixture.viewModel.trackingStatus)")
            return
        }
        #expect(fixture.viewModel.homeStatusText.hasPrefix("Snapshot at "))
        #expect(fixture.viewModel.availableFilters == [.all, .on])
    }

    ///
    /// Rows follow Settings, not the alphabet or the raw values: VoiceOver
    /// and Bold text in Vision, Reduce motion in Motion.
    ///
    @Test("Groups rows into sections in Settings order")
    func groupsRowsIntoSections() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })

        let sections = fixture.viewModel.sections
        #expect(sections.map(\.group) == [.vision, .motion])
        #expect(sections.first?.rows.map(\.type) == [.voiceOver, .boldText])
    }

    @Test("Filters by On and searches names and identifiers")
    func filtersAndSearches() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })

        fixture.viewModel.filter = .on
        #expect(fixture.viewModel.sections.flatMap(\.rows).map(\.type) == [.boldText])

        fixture.viewModel.filter = .all
        fixture.viewModel.searchText = "REDUCE_"
        #expect(fixture.viewModel.sections.flatMap(\.rows).map(\.type) == [.reduceMotion])

        fixture.viewModel.searchText = "voice"
        #expect(fixture.viewModel.sections.flatMap(\.rows).map(\.type) == [.voiceOver])

        fixture.viewModel.searchText = "nothing like this"
        #expect(fixture.viewModel.sections.isEmpty)
    }

    @Test("Marks a change, counts it, and announces it while the Monitor is on screen")
    func marksAndAnnouncesAChange() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })
        fixture.viewModel.isMonitorVisible = true

        fixture.system.values[.voiceOver] = .flag(true)
        fixture.center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        // The history records the change at once; the snapshot lands a turn later.
        await poll(until: { fixture.viewModel.row(for: "voice_over")?.isOn == true })

        let row = fixture.viewModel.row(for: "voice_over")
        #expect(fixture.viewModel.count(for: .changed) == 1)
        #expect(row?.changeDate != nil)
        #expect(row?.changeToken != 0)
        #expect(fixture.viewModel.row(for: "bold_text")?.changeToken == 0)
        #expect(row?.accessibilityLabel.hasPrefix("VoiceOver, on, changed at ") == true)
        #expect(fixture.announcements.messages == ["VoiceOver turned on"])

        let history = fixture.viewModel.history(for: "voice_over")
        #expect(history.map(\.event) == ["Turned on", "Off at launch"])
    }

    @Test("Announces nothing while the Monitor is off screen")
    func announcesNothingOffScreen() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })

        fixture.system.values[.voiceOver] = .flag(true)
        fixture.center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        await poll(until: { fixture.viewModel.row(for: "voice_over")?.isOn == true })

        #expect(fixture.announcements.messages.isEmpty)
    }

    ///
    /// Reconfiguring refreshes the Monitor with values read under the new
    /// configuration. A difference there is not something the user just
    /// changed, so it must not be announced as one.
    ///
    @Test("Announces nothing for a refresh after reconfiguring")
    func announcesNothingForAReconfiguration() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })
        fixture.viewModel.isMonitorVisible = true

        // Changed with no notification, so only the reconfiguration reads it.
        fixture.system.values[.voiceOver] = .flag(true)
        fixture.monitor.configureAccessibilityTracking(with: try Fixture.configuration(fetchType: .continuous))
        await poll(until: { fixture.viewModel.row(for: "voice_over")?.isOn == true })

        #expect(fixture.announcements.messages.isEmpty)
        // Not a change the user made just now, so the row does not flash either.
        #expect(fixture.viewModel.row(for: "voice_over")?.changeToken == 0)
    }

    ///
    /// The history holds the system's values, but the kit shows what the app
    /// reports. A transform that folds two text sizes into one flag must not
    /// turn a step between them into a change.
    ///
    @Test("Shows the history through the configured transform")
    func showsHistoryThroughTheTransform() async throws {
        let center = NotificationCenter()
        let system = SystemValues()
        let monitor = AccessibilityMonitor(notificationCenter: center, readState: system.read, launchDate: Date())
        monitor.configureAccessibilityTracking(
            with: try AccessibilityTrackingConfiguration(
                fetchType: .continuous,
                objects: [
                    AccessibilityTrackingObject(
                        type: .fontScale,
                        customIdentifier: "large_text",
                        transform: { .flag(($0.scaleValue ?? 1) >= 1.2) }
                    )
                ]
            )
        )
        let viewModel = AccessibilityMonitorViewModel(monitor: monitor, announce: { _ in })
        await poll(until: { !viewModel.states.isEmpty })

        // Large to extra large: still not large text.
        system.values[.fontScale] = .scale(19.0 / 17)
        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        await settle()

        #expect(viewModel.row(for: "large_text")?.changeDate == nil)
        #expect(viewModel.history(for: "large_text").map(\.event) == ["Off at launch"])

        // Then to an accessibility size: now it is.
        system.values[.fontScale] = .scale(40.0 / 17)
        center.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        await poll(until: { viewModel.row(for: "large_text")?.isOn == true })

        #expect(viewModel.row(for: "large_text")?.changeDate != nil)
        #expect(viewModel.history(for: "large_text").map(\.event) == ["Turned on", "Off at launch"])
        withExtendedLifetime(monitor) { }
    }

    @Test("Shares one plain-text line per setting")
    func sharesPlainText() async throws {
        let fixture = try Fixture(fetchType: .continuous)
        await poll(until: { !fixture.viewModel.states.isEmpty })

        let text = fixture.viewModel.shareItems().first as? String
        #expect(text == "VoiceOver (voice_over): Off\nBold text (bold_text): On\nReduce motion (reduce_motion): Off")
    }
}

// MARK: - Fixture

///
/// A monitor tracking three features whose system values the test sets, and
/// a view model on it that records its announcements. Bold text is on.
///
@MainActor
private struct Fixture {

    let center = NotificationCenter()
    let system = SystemValues()
    let monitor: AccessibilityMonitor
    let announcements = Announcements()
    let viewModel: AccessibilityMonitorViewModel

    init(fetchType: AccessibilityFetchType) throws {
        system.values[.boldText] = .flag(true)
        monitor = AccessibilityMonitor(notificationCenter: center, readState: system.read, launchDate: Date())
        monitor.configureAccessibilityTracking(with: try Self.configuration(fetchType: fetchType))
        let announcements = self.announcements
        viewModel = AccessibilityMonitorViewModel(monitor: monitor, announce: { announcements.messages.append($0) })
    }

    static func configuration(fetchType: AccessibilityFetchType) throws -> AccessibilityTrackingConfiguration {
        return try AccessibilityTrackingConfiguration(
            fetchType: fetchType,
            objects: [.reduceMotion, .boldText, .voiceOver].map { AccessibilityTrackingObject(type: $0) }
        )
    }
}

@MainActor
private final class Announcements {
    var messages = [String]()
}
