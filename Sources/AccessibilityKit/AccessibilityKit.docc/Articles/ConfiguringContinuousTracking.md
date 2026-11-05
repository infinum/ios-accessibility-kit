# Configuring continuous tracking

Follow accessibility changes for the life of the app.

## Overview

A single snapshot tells you what is enabled at one moment. To be told when something changes,
configure tracking once, then observe.

### Configuring

Build an ``AccessibilityTrackingConfiguration`` naming the features to follow and how often to
report, and hand it to
``AccessibilityKit/AccessibilityKit/configureAccessibilityTracking(with:)``. Application launch is
the natural place. Launch methods do not throw, and a rejected configuration is a mistake in a list
you wrote rather than a runtime condition, so surface it during development:

```swift
do {
    let configuration = try AccessibilityTrackingConfiguration(
        fetchType: .continuous,
        objects: [
            AccessibilityTrackingObject(type: .boldText),
            AccessibilityTrackingObject(type: .voiceOver)
        ]
    )
    AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
} catch {
    assertionFailure("Invalid accessibility tracking configuration: \(error)")
}
```

``AccessibilityFetchType/continuous`` reports on every change.
``AccessibilityFetchType/initial`` reports only once, when observation begins.

The initialiser throws ``AccessibilityTrackingError/duplicateIdentifier(_:)`` if two tracking
objects would be reported under the same identifier, since the snapshot would carry entries a
consumer cannot tell apart. One feature can still be tracked twice — raw and corrected, say — as
long as the two are reported under different identifiers, so give at least one of them a
`customIdentifier`.

### Observing

``AccessibilityKit/AccessibilityKit/observeAccessibilityTracking(completion:)`` delivers the first
snapshot as soon as observation begins, and then follows the configured fetch type:

```swift
AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
    // handle the snapshot
}
```

Completions are delivered asynchronously on the main queue, so a completion never runs inside your
own call to observe.

Only one observation is active at a time — calling this again replaces the previous completion. A
replaced completion is not called again, not even for a snapshot already in flight, and the
replacement receives only snapshots taken after it was registered.
Reconfiguring tracking keeps the observation you already registered, but emits no snapshot of its
own: the next one arrives at the next change, and only if the new configuration is
``AccessibilityFetchType/continuous``. A snapshot taken under the replaced configuration and not
yet delivered is dropped, for the completion and the accessibility monitor alike. The monitor is
then refreshed with the new configuration's features, without waiting for a change, on the main
queue like any other delivery. Your completion is not: it keeps what
it last received until the next change, which only a continuous configuration delivers.

### Isolation

``AccessibilityKit/AccessibilityKit`` is `@MainActor`. Reading accessibility state means touching
main-actor `UIKit` state, so the whole reading path is isolated to the main actor. Call it from the
main actor, or `await` it from elsewhere:

```swift
await AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
```
