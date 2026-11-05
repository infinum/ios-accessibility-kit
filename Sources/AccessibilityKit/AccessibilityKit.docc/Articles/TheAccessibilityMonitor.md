# The accessibility monitor

Show the tracked features and their current values on screen.

## Overview

The monitor is a screen listing every tracking object with the identifier it is reported under
and its value. It is a development aid: each row is reported under the same identifier, and with
the same `transform` applied, as in the snapshots your app receives.

The list follows changes only when tracking is configured with
``AccessibilityFetchType/continuous``. Under ``AccessibilityFetchType/initial`` it shows the values
from when it was presented.

It observes through
``AccessibilityKit/AccessibilityKit/observeAccessibilityTracking(completion:)``, so tracking must be
configured first. See <doc:ConfiguringContinuousTracking>. Only one observation is active at a
time, so showing the monitor replaces your app's own; register again once it is dismissed.

### From UIKit

``AccessibilityKit/AccessibilityKit/presentAccessibilityMonitor(on:)`` presents it:

```swift
AccessibilityKit.shared.presentAccessibilityMonitor(on: viewController)
```

### From SwiftUI

Use ``AccessibilityMonitorView`` directly. It does not dismiss itself — the closure is where you
do that:

```swift
.sheet(isPresented: $isPresented) {
    AccessibilityMonitorView { isPresented = false }
}
```
