# Getting the current snapshot

Read the accessibility features a user has enabled, right now.

## Overview

``AccessibilityKit/AccessibilityKit/currentAccessibilitySnapshot(for:)`` reads a set of features
and returns their state. Tracking does not need to be configured first — this works from a cold
start.

Describe what to read with ``AccessibilityTrackingObject``, one per feature:

```swift
let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
    for: [
        AccessibilityTrackingObject(type: .voiceOver),
        AccessibilityTrackingObject(type: .boldText)
    ]
)

for state in snapshot.states {
    print(state.identifier, state.value.flagValue)
}
```

Each identifier may appear only once: entries a consumer cannot tell apart are the thing being
prevented. The call throws ``AccessibilityTrackingError/duplicateIdentifier(_:)`` when two
tracking objects would be reported under one identifier. The same feature can appear twice under
two custom identifiers.

### Reporting a feature under your own identifier

Pass a `customIdentifier` when the identifier you record differs from the library's default:

```swift
AccessibilityTrackingObject(type: .fontScale, customIdentifier: "text_size")
```

### Correcting the value

A font scale of `1.2353` may only be interesting as "large text is enabled". A `transform` corrects
the value where it is produced, so the encoded output carries the corrected value too. Passed to
``AccessibilityKit/AccessibilityKit/currentAccessibilitySnapshot(for:)``, it corrects only that
snapshot; to correct observed changes and the accessibility monitor as well, include it in the
configuration passed to
``AccessibilityKit/AccessibilityKit/configureAccessibilityTracking(with:)``:

```swift
AccessibilityTrackingObject(
    type: .fontScale,
    customIdentifier: "large_text_enabled",
    transform: { value in .flag((value.scaleValue ?? 1) >= 1.2) }
)
```

To correct a value you already hold, use ``AccessibilityState/withValue(_:)`` and rebuild the
snapshot with ``AccessibilitySnapshot/init(states:)``.

### Sending it onward

``AccessibilitySnapshot`` is `Encodable`, and ``AccessibilitySnapshot/toDictionary()`` converts it.
The conversion throws whatever `JSONEncoder` or `JSONSerialization` raises, or
``AccessibilityEncodingError/notAJSONObject`` if the encoded form is not a JSON object, so it
reports a failure rather than handing back `nil`:

```swift
let payload = try snapshot.toDictionary()
```

The dictionary is the encoded form:

```json
{
    "values": [
        { "identifier": "bold_text", "value": true },
        { "identifier": "voice_over", "value": false }
    ]
}
```
