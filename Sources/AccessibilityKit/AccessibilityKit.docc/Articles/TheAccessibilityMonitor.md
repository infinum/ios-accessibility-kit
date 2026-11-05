# The kit and its Monitor

Look at the accessibility settings while your app runs.

## Overview

The kit is a development aid that sits above your app. It has one way in and one home: open it,
and a sheet shows the kit's tools. Its first tool is the Monitor, which lists every tracked
feature under the identifier it is reported under, with the same `transform` applied, as in the
snapshots your app receives. Each feature opens a detail screen with its identifier, the
notification tracking listens to, and what it has done this session.

The Monitor follows changes only when tracking is configured with
``AccessibilityFetchType/continuous``, marking each setting that changed since launch. Under
``AccessibilityFetchType/initial`` it shows the values from when it was opened. Reconfiguring
tracking refreshes it with the newly configured features. Until tracking is configured, it explains
how to set it up. See <doc:ConfiguringContinuousTracking>.

The kit observes tracking on its own, so opening it does not affect an observation your app
registered with ``AccessibilityKit/AccessibilityKit/observeAccessibilityTracking(completion:)``.

### Opening the kit

Turn on its entry points, in debug builds only:

```swift
#if DEBUG
AccessibilityKit.shared.entryPoints = [.floatingButton, .shake]
#endif
```

The floating button lives in a window of the kit's own, above your app's. Drag it to any corner;
long-press it to hide it until the next launch. Shaking is off unless you include it, so an app
that uses shake to undo keeps it.

To open the kit from code, call ``AccessibilityKit/AccessibilityKit/present()``.

### Showing the Monitor yourself

Use ``AccessibilityMonitorView`` to show the Monitor somewhere of your own. It does not dismiss
itself — the closure is where you do that:

```swift
.sheet(isPresented: $isPresented) {
    AccessibilityMonitorView { isPresented = false }
}
```
