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
tracking objects would be reported under one identifier. The same feature can appear twice, as
long as the two are reported under different identifiers, so give at least one of them a
`customIdentifier`.

### Reporting a feature under your own identifier

Every feature is reported under a default identifier, the raw value of its ``AccessibilityType``:

| Feature                     | Default identifier            | Value |
|:----------------------------|:------------------------------|:------|
| AssistiveTouch              | `assistive_touch`             | flag  |
| Bold text                   | `bold_text`                   | flag  |
| Button shapes               | `button_shapes`               | flag  |
| Closed captioning           | `closed_captioning`           | flag  |
| Cross-fade transitions      | `cross_fade_transitions`      | flag  |
| Darker system colors        | `darker_system_colors`        | flag  |
| Differentiate without color | `differentiate_without_color` | flag  |
| Font scale                  | `font_scale`                  | scale |
| Grayscale                   | `grayscale`                   | flag  |
| Guided Access               | `guided_access`               | flag  |
| Invert colors               | `invert_colors`               | flag  |
| Mono audio                  | `mono_audio`                  | flag  |
| On/off switch labels        | `on_off_switch_labels`        | flag  |
| Reduce motion               | `reduce_motion`               | flag  |
| Reduce transparency         | `reduce_transparency`         | flag  |
| Shake to undo               | `shake_to_undo`               | flag  |
| Speak screen                | `speak_screen`                | flag  |
| Speak selection             | `speak_selection`             | flag  |
| Switch Control              | `switch_control`              | flag  |
| Video autoplay              | `video_autoplay`              | flag  |
| VoiceOver                   | `voice_over`                  | flag  |

A flag is ``AccessibilityValue/flag(_:)``, whether the setting is on. A scale is
``AccessibilityValue/scale(_:)``, where `1.0` is the default text size. These are the values
before any `transform`: a transform can return a different kind of value under the same
identifier, so when yours does, give the feature a `customIdentifier` and anyone reading the
output won't expect the default kind.

Pass a `customIdentifier` when the identifier you record differs from the default:

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
snapshot with ``AccessibilitySnapshot/init(states:date:)``.

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
