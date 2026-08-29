# The accessibility monitor

Show the tracked features and their current values on screen.

## Overview

The monitor is a screen listing every tracked accessibility feature with the identifier it is
reported under and its current value. It is a development aid: it shows exactly what your app
reports, including any `transform` applied, so the screen and your payload can never disagree.

It observes through
``AccessibilityKit/AccessibilityKit/observeAccessibilityTracking(completion:)``, so tracking must be
configured first. See <doc:ConfiguringContinuousTracking>.

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
