# Configuring continuous tracking

Follow accessibility changes for the life of the app.

## Overview

A single snapshot tells you what is enabled at one moment. To be told when something changes,
configure tracking once, then observe.

### Configuring

Build an ``AccessibilityTrackingConfiguration`` naming the features to follow and how often to
report, and hand it to
``AccessibilityKit/AccessibilityKit/configureAccessibilityTracking(with:)``. Application launch is
the natural place:

```swift
let configuration = try AccessibilityTrackingConfiguration(
    fetchType: .continuous,
    objects: [
        AccessibilityTrackingObject(type: .boldText),
        AccessibilityTrackingObject(type: .voiceOver)
    ]
)

AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
```

``AccessibilityFetchType/continuous`` reports on every change.
``AccessibilityFetchType/initial`` reports only once, when observation begins.

The initialiser throws ``AccessibilityTrackingError/duplicateType(_:)`` if a feature appears more
than once, and ``AccessibilityTrackingError/duplicateIdentifier(_:)`` if two features would be
reported under the same identifier — either way, the snapshot would carry entries a consumer
cannot tell apart.

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
snapshot already in flight still reaches the completion registered when it was taken, so a
replacement never receives someone else's first snapshot.
Reconfiguring tracking keeps the observation you already registered, but emits no snapshot of its
own: the next one arrives at the next change, and only if the new configuration is
``AccessibilityFetchType/continuous``.

### Isolation

``AccessibilityKit/AccessibilityKit`` is `@MainActor`. Reading accessibility state means touching
main-actor `UIKit` state, so the whole reading path is isolated to the main actor. Call it from the
main actor, or `await` it from elsewhere:

```swift
await AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
```
