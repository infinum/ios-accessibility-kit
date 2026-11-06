# Migration guide

## Migrating to 2.0

* **iOS 15 and above.** The package no longer supports iOS 14.
* **Keep the observation.** `observeAccessibilityTracking(completion:)` now returns an `AccessibilityObservation`, and the observation ends when it is released. Code that ignores the result still compiles, with an "unused result" warning, but receives no snapshots. Store the result in a property. Calling the method again no longer replaces the previous completion: both receive snapshots until each observation ends.
* **Display names in sentence case.** `AccessibilityState.name` now matches the new `AccessibilityType.displayName`: "Bold text" rather than "Bold Text", "AssistiveTouch" rather than "Assistive Touch".
* **Open the kit instead of the monitor.** `presentAccessibilityMonitor(on:)` is deprecated. Use `AccessibilityKit.shared.present()`, or turn on `entryPoints` so people can open the kit themselves. `AccessibilityMonitorView` is still available, and shows the redesigned Monitor.
