# AccessibilityKit

## Description

**AccessibilityKit** is a simple library that gives developers the ability to track accessibility features enabled by the user in real-time (through the application lifecycle).

The main idea of the library is to give the developer an update whenever a user changes the accessibility features and gets the currently enabled accessibility features. It is important to specify which accessibility features should be tracked - can be only one or all of them, which creates a snapshot every time the change is made based on the tracked accessibility features.

This library currently supports the **Swift** programming language.

## Table of contents

* [Requirements](#requirements)
* [Getting started](#getting-started)
* [Usage](#usage)
* [Contributing](#contributing)
* [License](#license)
* [Credits](#credits)

## Requirements

* iOS 15 and above
* Xcode 16 and above (Swift 6 toolchain)

## Getting started

AccessibilityKit is available through [Swift Package Manager (SPM)](https://www.swift.org/package-manager/).

To install it via SPM, open your project in Xcode, go to `File` -> `Add Package Dependencies...`, and enter the URL of the repository:

```text
https://github.com/infinum/ios-accessibility-kit
```

Or add it to your own `Package.swift`. Declare the package, then list the product under the target that imports it:

```swift
dependencies: [
    .package(url: "https://github.com/infinum/ios-accessibility-kit", from: "2.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "AccessibilityKit", package: "ios-accessibility-kit")
        ]
    )
]
```

The full API reference and guides are written in DocC and published on the [Swift Package Index](https://swiftpackageindex.com/infinum/ios-accessibility-kit/documentation). You can also browse them in Xcode with `Product` -> `Build Documentation`.

Upgrading from 1.x? See the [migration guide](MIGRATION.md).

## Usage

### Features

In this chapter, some of the essential pieces of the library will be introduced.
`AccessibilityKit` is the main class used to set up the *AccessibilityKit* library. It is defined as a singleton and can be used in different ways.

#### Accessibility state

This library provides an easy way to get the current state of the accessibility features on a device. 

The method `currentAccessibilitySnapshot(for:)`  returns a snapshot of a type `AccessibilitySnapshot` containing all the necessary information about the state of accessibility features on a current device. 

To configure which states will be tracked, pass an array of values of type `AccessibilityTrackingObject`. It takes the `type` of accessibility feature to track, defined by the `AccessibilityType` enum, and optionally a `customIdentifier` to report that feature under and a `transform` to correct its value.

Give every tracking object its own identifier. The configuration's initializer and `currentAccessibilitySnapshot(for:)` throw `AccessibilityTrackingError.duplicateIdentifier(_:)` when two objects would be reported under the same identifier. One feature can be tracked twice, for example raw and corrected, as long as the two are reported under different identifiers, so give at least one of them a `customIdentifier`.

A default identifier is used for every tracked accessibility feature when a custom identifier is not used. Default identifiers are defined as:

| Accessibility feature         | Default identifier            | Return type   |
|:------------------------------|:------------------------------|:--------------|
| Assistive touch               | assistive_touch               | Bool          |
| Bold text                     | bold_text                     | Bool          |
| Button shapes                 | button_shapes                 | Bool          |
| Closed captioning             | closed_captioning             | Bool          |
| Cross fade transitions        | cross_fade_transitions        | Bool          |
| Darker system colors          | darker_system_colors          | Bool          |
| Differentiate without color   | differentiate_without_color   | Bool          |
| Font scale                    | font_scale                    | Double        |
| Grayscale                     | grayscale                     | Bool          |
| Guided access                 | guided_access                 | Bool          |
| Invert colors                 | invert_colors                 | Bool          |
| Mono audio                    | mono_audio                    | Bool          |
| On/off switch labels          | on_off_switch_labels          | Bool          |
| Reduce motion                 | reduce_motion                 | Bool          |
| Reduce transparency           | reduce_transparency           | Bool          |
| Shake to undo                 | shake_to_undo                 | Bool          |
| Speak screen                  | speak_screen                  | Bool          |
| Speak selection               | speak_selection               | Bool          |
| Switch control                | switch_control                | Bool          |
| Video autoplay                | video_autoplay                | Bool          |
| VoiceOver                     | voice_over                    | Bool          |

`AccessibilityType` conforms to `CaseIterable`, so every supported feature can be tracked without listing them by hand:

```swift
let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
    for: AccessibilityType.allCases.map { AccessibilityTrackingObject(type: $0) }
)
```

#### Correcting a value

Sometimes the value a feature reports is not the value an app wants to record — for example, a font scale of `1.2353` may only be interesting as "large text is enabled". Pass a `transform` to `AccessibilityTrackingObject` to correct the value where it is produced, so the encoded output and `toDictionary()` carry the corrected value too. A tracking object passed to `currentAccessibilitySnapshot(for:)` corrects only that snapshot; to correct observed changes and the accessibility monitor as well, include it in the configuration passed to `configureAccessibilityTracking(with:)`.

```swift
AccessibilityTrackingObject(
    type: .fontScale,
    customIdentifier: "large_text_enabled",
    transform: { value in .flag((value.scaleValue ?? 1) >= 1.2) }
)
```

When a transform changes the kind of value, as the font scale's `Double` becoming a `Bool` above, give the tracking object a `customIdentifier`. Otherwise the value is reported under the default identifier with a different type than the table above lists. The same goes for tracking one feature more than once, for example raw and corrected: every tracked object needs its own identifier, since identifiers key both the encoded output and the rows of the accessibility monitor.

A state can also be corrected after the fact with `withValue(_:)`, which preserves the feature's `type`, `name` and `identifier`:

```swift
let corrected = state.withValue(.flag(true))
```

Corrected states can be gathered back into a snapshot, which keeps `Encodable` and `toDictionary()` available:

```swift
let snapshot = AccessibilitySnapshot(states: [corrected])
```

#### Configuration

To track accessibility states in real-time, `AccessibilityKit` should be configured via the method `configureAccessibilityTracking(with:)`.

This method should get a configuration object as a parameter with all accessibility features that should be tracked. The type used for that is `AccessibilityTrackingConfiguration`.

`AccessibilityTrackingConfiguration` in its init method defines `fetchType` of type `AccessibilityFetchType` which can be `initial` or `continuous`. Based on the fetch type, values will be returned only once (`initial`), or it will continuously observe changes (`continuous`). The first snapshot is delivered as soon as observation begins. Reconfiguring tracking replaces the tracked features and keeps any observation already registered, but emits no snapshot of its own to it, and a snapshot taken under the previous configuration that has not been delivered yet is dropped. An open Monitor, unlike your observations, is then handed a snapshot of the newly configured features.

Another parameter needed for this configuration is an object of the type `AccessibilityTrackingObject`.

#### Observing changes

After the `AccessibilityKit` is configured, you can observe changes via `observeAccessibilityTracking(completion:)`.

This method will return one or multiple snapshots based on the `fetchType` configured in the `AccessibilityTrackingConfiguration` init method.

The method returns an `AccessibilityObservation`. Keep it for as long as you want snapshots: the observation ends when you call `cancel()` on it or release it, and its completion is not called again after that, not even for a snapshot already in flight. Any number of observations can run side by side, and each receives its own first snapshot and every change after it. Reconfiguring tracking does not end an observation, so capture the completion's owner weakly.

An object returned in the completion is of a type `AccessibilitySnapshot`, which carries an array of the states for every tracked accessibility feature, sorted by accessibility type, and by identifier where one feature is tracked more than once, plus the `date` it was taken. Snapshots are delivered on the main queue.

The object type in the array is `AccessibilityState` which provides `type`, `name`, `value`, and `identifier`. All those properties can be used to identify every accessibility feature based on the type, name, value, or identifier.

`AccessibilitySnapshot` is `Encodable`, and `toDictionary()` converts it for sending onward. It throws rather than reporting failure as `nil`: whatever `JSONEncoder` or `JSONSerialization` raises, or `AccessibilityEncodingError.notAJSONObject` if the encoded form is not a JSON object. The encoded form is a `values` array of `identifier` / `value` pairs:

```json
{
    "values": [
        { "identifier": "bold_text", "value": true },
        { "identifier": "font_scale", "value": 1.2352941176470589 },
        { "identifier": "voice_over", "value": true }
    ]
}
```

The identifiers are the default ones from the table above. Any feature given a `customIdentifier` appears under that identifier instead.

#### The kit

**AccessibilityKit** also has a user interface for looking at the settings while the app runs: the kit. It opens as a sheet over the app, from a window of its own, and its home lists the kit's tools. The first tool is the Monitor, which lists every tracked feature grouped as in Settings, with search, On and Changed filters, and a detail screen per feature showing its identifier, the notification tracking listens to, and what it has done this session. It can share the snapshot as text and JSON.

Turn on the ways people can open it with `entryPoints`: a floating button above the app, a shake of the device, or both. The kit is a debugging aid, so set them in debug builds only:

```swift
#if DEBUG
AccessibilityKit.shared.entryPoints = [.floatingButton, .shake]
#endif
```

The button can be dragged to any corner and stays there across launches; long-press it to hide it until the next launch. Shaking is off unless you include it, so an app that uses shake to undo keeps it. To open the kit from code, call `AccessibilityKit.shared.present()`.

The kit observes the configured tracking on its own, so opening it does not affect an observation the app registered with `observeAccessibilityTracking(completion:)`. The Monitor follows changes only when tracking is configured as `continuous`, marking each setting that changed since launch; under `initial` it shows the values from when it was opened. Until tracking is configured, it explains how to set it up.

To show the Monitor somewhere of your own, embed `AccessibilityMonitorView`; it does not dismiss itself, so the closure you pass is where you do that. `presentAccessibilityMonitor(on:)` still works, but is deprecated in favour of `present()`.

### Examples

To add **AccessibilityKit** to your project, install it with Swift Package Manager as described in [Getting started](#getting-started).

#### Getting current state

To get the latest state of accessibility features, there is no need to define **AccessibilityKit**. You can use a method for this anytime.

```swift
let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
    for: [
        AccessibilityTrackingObject(type: .boldText),
        AccessibilityTrackingObject(
            type: .fontScale, 
            customIdentifier: "font_scaling"
        )
    ]
)
```

#### Observing changes through the app lifecycle

If there is a need to observe accessibility feature changes, the method above is not enough. Instead of that, **AccessibilityKit** should be configured first.

To do that, use  `AccessibilityKit.shared.configureAccessibilityTracking(with:)` in the `AppDelegate`'s method `application(_:didFinishLaunchingWithOptions:)` to configure tracking for the app lifecycle.

```swift
do {
    let configuration = try AccessibilityTrackingConfiguration(
        fetchType: .continuous,
        objects: [
            AccessibilityTrackingObject(type: .boldText),
            AccessibilityTrackingObject(
                type: .buttonShapes,
                customIdentifier: "button_shapes_enabled"
            ),
            AccessibilityTrackingObject(
                type: .fontScale,
                customIdentifier: "font_scaling"
            ),
            AccessibilityTrackingObject(type: .reduceMotion),
            AccessibilityTrackingObject(type: .voiceOver)
        ]
    )
    AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
} catch {
    assertionFailure("Invalid accessibility tracking configuration: \(error)")
}
```

No two tracking objects may share an identifier; the initializer throws `AccessibilityTrackingError.duplicateIdentifier(_:)` instead of reporting entries a consumer cannot tell apart. Launch methods do not throw, and a rejected configuration is a mistake in the list rather than a runtime condition, so the sample surfaces it during development.

After that, the observing method can be used afterward to get the latest accessibility feature states.

```swift
observation = AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
    ...
}
```

Keep `observation` in a property: releasing it ends the observation.

#### Opening the kit

Turn on the kit's entry points once tracking is configured:

```swift
#if DEBUG
AccessibilityKit.shared.entryPoints = [.floatingButton, .shake]
#endif
```

To show only the Monitor, in a sheet of your own, embed the view instead:

```swift
.sheet(isPresented: $isPresented) {
    AccessibilityMonitorView { isPresented = false }
}
```

## Contributing

We believe that the community can help us improve and build better a product.
Please refer to our [contributing guide](CONTRIBUTING.md) to learn about the types of contributions we accept and the process for submitting them.

To ensure that our community remains respectful and professional, we defined a [code of conduct](CODE_OF_CONDUCT.md) that we expect all contributors to follow.

We appreciate your interest and look forward to your contributions.

## License

```text
Copyright 2026 Infinum

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Credits

Maintained and sponsored by [Infinum](https://infinum.com).
