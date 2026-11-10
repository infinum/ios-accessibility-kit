# Migration guide

## Migrating to 2.0

* **iOS 15 and Xcode 16.** The package no longer supports iOS 14, and it is built in the Swift 6 language mode, so it needs Xcode 16 or later.
* **Call it from the main actor.** `AccessibilityKit` is `@MainActor`, because reading accessibility state touches main-actor `UIKit` state. Call it from the main actor, or `await` it from elsewhere.
* **`try` the snapshot and the configuration.** `currentAccessibilitySnapshot(for:)` and `AccessibilityTrackingConfiguration.init(fetchType:objects:)` now throw `AccessibilityTrackingError.duplicateIdentifier(_:)` when two tracking objects would be reported under the same identifier. Give at least one of them a `customIdentifier`.
* **`toDictionary()` throws, and only snapshots have it.** It returns `[String: Any]` instead of `[String: Any]?`, and throws what `JSONEncoder` or `JSONSerialization` raises, or `AccessibilityEncodingError.notAJSONObject`. Write `try snapshot.toDictionary()` where you used `if let`. It is no longer added to every `Encodable` type, only to `AccessibilitySnapshot`.
* **Keep the observation.** `observeAccessibilityTracking(completion:)` now returns an `AccessibilityObservation`, and the observation ends when it is released. Code that ignores the result still compiles, with an "unused result" warning, but receives no snapshots. Store the result in a property. Calling the method again no longer replaces the previous completion: both receive snapshots until each observation ends.
* **Display names in sentence case.** `AccessibilityState.name` now matches the new `AccessibilityType.displayName`: "Bold text" rather than "Bold Text", "AssistiveTouch" rather than "Assistive Touch".
* **Open the kit instead of the monitor.** `presentAccessibilityMonitor(on:)` is deprecated. Use `AccessibilityKit.shared.present()`, or turn on `entryPoints` so people can open the kit themselves. `AccessibilityMonitorView` is still available, and shows the redesigned Monitor.
