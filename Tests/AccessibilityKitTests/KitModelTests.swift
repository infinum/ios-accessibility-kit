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

    // MARK: - Registering with a tracker

    ///
    /// The view model is created as the kit opens and its first update lands
    /// a turn later. A tracked app must not flash the nothing-tracked screen
    /// in between.
    ///
    @Test("Reports live tracking from the start, before the first update lands")
    func reportsLiveTrackingFromTheStart() throws {
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: ManualDeliveryQueue())
        tracker.configureAccessibilityTracking(with: try AccessibilityTrackingConfiguration(
            fetchType: .continuous,
            objects: [AccessibilityTrackingObject(type: .voiceOver)]
        ))
        let viewModel = AccessibilityMonitorViewModel(tracker: tracker, announce: { _ in })

        #expect(viewModel.trackingStatus == .live)
        #expect(viewModel.allRows.isEmpty)
    }

    @Test("Reports nothing tracked before tracking is configured")
    func reportsNothingTracked() {
        let queue = ManualDeliveryQueue()
        let viewModel = AccessibilityMonitorViewModel(tracker: AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue))
        queue.run()

        #expect(viewModel.trackingStatus == .notTracked)
        #expect(viewModel.homeStatusText == "Tracking not set up")
    }

    @Test("Reports nothing tracked when tracking is configured with no features")
    func reportsNothingTrackedForAnEmptyConfiguration() throws {
        let queue = ManualDeliveryQueue()
        let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: queue)
        tracker.configureAccessibilityTracking(with: try AccessibilityTrackingConfiguration(fetchType: .continuous, objects: []))
        let viewModel = AccessibilityMonitorViewModel(tracker: tracker)
        queue.run()

        #expect(viewModel.trackingStatus == .notTracked)
        #expect(viewModel.monitorStatusText == "Tracking not set up")
    }

    // MARK: - Showing an update

    @Test("Reports live tracking with its counts")
    func reportsLiveTracking() {
        let fixture = Fixture()
        fixture.deliver()

        #expect(fixture.viewModel.trackingStatus == .live)
        #expect(fixture.viewModel.homeStatusText == "Live · 1 of 3 settings on")
        #expect(fixture.viewModel.monitorStatusText == "Live · 3 tracked · 1 on")
        #expect(fixture.viewModel.availableFilters == [.all, .on, .changed])
    }

    @Test("Reports a one-time snapshot, without the Changed filter")
    func reportsASnapshot() {
        let fixture = Fixture()
        fixture.deliver(status: .snapshot(Date()))

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
    func groupsRowsIntoSections() {
        let fixture = Fixture()
        fixture.deliver()

        let sections = fixture.viewModel.sections
        #expect(sections.map(\.group) == [.vision, .motion])
        #expect(sections.first?.rows.map(\.type) == [.voiceOver, .boldText])
    }

    @Test("Filters by On and searches names and identifiers")
    func filtersAndSearches() {
        let fixture = Fixture()
        fixture.deliver()

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
    func marksAndAnnouncesAChange() {
        let fixture = Fixture()
        fixture.deliver()
        fixture.viewModel.isMonitorVisible = true

        fixture.deliver(on: [.boldText, .voiceOver], reason: .change, changed: [.voiceOver])

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
    func announcesNothingOffScreen() {
        let fixture = Fixture()
        fixture.deliver()

        fixture.deliver(on: [.boldText, .voiceOver], reason: .change, changed: [.voiceOver])

        #expect(fixture.viewModel.row(for: "voice_over")?.isOn == true)
        #expect(fixture.announcements.messages.isEmpty)
    }

    ///
    /// Reconfiguring refreshes the Monitor with values read under the new
    /// configuration. A difference there is not something the user just
    /// changed, so it must not be announced as one.
    ///
    @Test("Announces nothing for a refresh after reconfiguring")
    func announcesNothingForAReconfiguration() {
        let fixture = Fixture()
        fixture.deliver()
        fixture.viewModel.isMonitorVisible = true

        fixture.deliver(on: [.boldText, .voiceOver], reason: .reconfiguration)

        #expect(fixture.viewModel.row(for: "voice_over")?.isOn == true)
        #expect(fixture.announcements.messages.isEmpty)
        // Not a change the user made just now, so the row does not flash either.
        #expect(fixture.viewModel.row(for: "voice_over")?.changeToken == 0)
    }

    @Test("Shares one plain-text line per setting")
    func sharesPlainText() {
        let fixture = Fixture()
        fixture.deliver()

        let text = fixture.viewModel.shareItems().first as? String
        #expect(text == "VoiceOver (voice_over): Off\nBold text (bold_text): On\nReduce motion (reduce_motion): Off")
    }
}

// MARK: - Fixture

///
/// A view model on a tracker that is never configured, so the tracker
/// delivers nothing: each test hands the view model its updates itself,
/// for VoiceOver, Bold text and Reduce motion, and reads what it shows.
/// Announcements are recorded.
///
@MainActor
private struct Fixture {

    let tracker = AccessibilityTracker(notificationCenter: NotificationCenter(), deliveryQueue: ManualDeliveryQueue())
    let announcements = Announcements()
    let viewModel: AccessibilityMonitorViewModel

    init() {
        let announcements = self.announcements
        viewModel = AccessibilityMonitorViewModel(tracker: tracker, announce: { announcements.messages.append($0) })
    }

    ///
    /// Hands the view model an update in which the features in `on` are on
    /// and the rest off. A feature in `changed` was off at launch and changed
    /// to on since; every other feature has had its value since launch.
    ///
    func deliver(
        on: Set<AccessibilityType> = [.boldText],
        status: TrackingStatus = .live,
        reason: TrackerUpdate.Reason = .registration,
        changed: Set<AccessibilityType> = []
    ) {
        let launch = Date(timeIntervalSinceNow: -60)
        let states = [AccessibilityType.reduceMotion, .boldText, .voiceOver].map { type in
            AccessibilityState(type: type, name: type.displayName, value: .flag(on.contains(type)))
        }
        var histories = [String: [AccessibilityHistoryEntry]]()
        for (index, state) in states.enumerated() {
            let sequence = index * 2
            if changed.contains(state.type) {
                histories[state.identifier] = [
                    AccessibilityHistoryEntry(sequence: sequence, date: launch, value: .flag(false), kind: .launch),
                    AccessibilityHistoryEntry(sequence: sequence + 1, date: Date(), value: state.value, kind: .change)
                ]
            } else {
                histories[state.identifier] = [
                    AccessibilityHistoryEntry(sequence: sequence, date: launch, value: state.value, kind: .launch)
                ]
            }
        }
        viewModel.trackerDidUpdate(TrackerUpdate(
            snapshot: AccessibilitySnapshot(states: states),
            histories: histories,
            status: status,
            reason: reason
        ))
    }
}

@MainActor
private final class Announcements {
    var messages = [String]()
}
