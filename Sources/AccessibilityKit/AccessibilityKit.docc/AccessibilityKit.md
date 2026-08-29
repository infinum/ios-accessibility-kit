# ``AccessibilityKit``

Track the accessibility features a user has enabled, as they change.

## Overview

Users configure accessibility features — VoiceOver, larger text, reduced motion — in Settings, and
can change them at any time while your app is running. **AccessibilityKit** reads those settings and
reports them as a snapshot you can inspect, encode and send onward.

There are two ways to use it. For a single reading, ask for a snapshot directly:

```swift
let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
    for: [AccessibilityTrackingObject(type: .voiceOver)]
)
```

To follow changes for the life of the app, configure tracking once and then observe. See
<doc:ConfiguringContinuousTracking>.

## Topics

### Essentials

- <doc:GettingTheCurrentSnapshot>
- <doc:ConfiguringContinuousTracking>
- <doc:TheAccessibilityMonitor>

### Reading accessibility state

- ``AccessibilityKit/AccessibilityKit``
- ``AccessibilitySnapshot``
- ``AccessibilityState``

### Describing what to track

- ``AccessibilityType``
- ``AccessibilityTrackingObject``
- ``AccessibilityTrackingConfiguration``
- ``AccessibilityFetchType``

### Values

- ``AccessibilityValue``

### Errors

- ``AccessibilityTrackingError``
- ``AccessibilityEncodingError``

### User interface

- ``AccessibilityMonitorView``
