# AccessibilityKit

## About

**AccessibilityKit** is a simple library that gives developers the ability to track accessibility features enabled by the user in real-time (through the application lifecycle).

The main idea of the library is to give the developer an update whenever a user changes the accessibility features and gets the currently enabled accessibility features. It is important to specify which accessibility features should be tracked - can be only one or all of them, which creates a snapshot every time the change is made based on the tracked accessibility features.

This library currently supports the **Swift** programming language.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory.

## Requirements

* iOS 10 and above
* Xcode 10 and above

## Installation

AccessibilityKit is available through [CocoaPods](https://cocoapods.org) and [Swift Package Manager](https://www.swift.org/package-manager/).

To install it via Cocoapods, add the following line to your Podfile:

```ruby
pod 'AccessibilityKit'
```

## Usage

### Features

In this chapter, some of the essential pieces of the library will be introduced.
`AccessibilityKit` is the main class used to set up the *AccessibilityKit* library. It is defined as a singleton and can be used in different ways.

#### Accessibility state

This library provides an easy way to get the current state of the accessibility features on a device. 

The method `currentAccessibilitySnapshot(for:)`  returns a snapshot of a type `AccessibilitySnapshot` containing all the necessary information about the state of accessibility features on a current device. 

To configure which states will be tracked, pass an array of values of type `AccessibilityTrackingObject`. This class needs two parameters; the `type` defines the accessibility feature you want to track - defined as `AccessibilityType` enum, and another parameter `customIdentifier` of a type `String?` which is optional and defines a custom identifier that will be used for that accessibility feature.

A default identifier is used for every tracked accessibility feature when a custom identifier is not used. Default identifiers are defined as:

| Accessibility feature         | Default identifier            | Return type   |
|:------------------------------|:------------------------------|:--------------|
| Assistive touch               | assistive_touch               | Bool          |
| Bold text                     | bold_text                     | Bool          |
| Button shapes                 | button_shapes                 | Bool          |
| Closed captioning             | closed_captioning             | Bool          |
| Cross fade transitions        | cross_fade_transitions        | Bool          |
| Darked system colors          | darker_system_colors          | Bool          |
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

#### Configuration

To track accessibility states in real-time, `AccessibilityKit` should be configured via the method `configureAccessibilityTracking(with:)`.

This method should get a configuration object as a parameter with all accessibility features that should be tracked. The class used for that is `AccessibilityTrackingConfiguration`.

`AccessibilityTrackingConfiguration` class in its init method defines `fetchType` of type `AccessibilityFetchType` which can be `initial` or `continuous`. Based on the fetch type, values will be returned only one (`initial`), or it will continuously observe changes (`continuous`). The important note is that the first snapshot of the accessibility states will be returned immediately after tracking is configured.

Another parameter needed for this configuration is an object of the type `AccessibilityTrackingObject`.

#### Observing changes

After the `AccessibilityKit` is configured, you can observe changes via` observeAccessibilityTracking(completion:)`. 

This method will return one or multiple snapshots based on the `fetchType` configured in the `AccessibilityTrackingConfiguration` init method.

An object returned in the completion is of a type `AccessibilitySnapshot` which returns an array of the states for every of the tracked accessibility features.

The object type in the array is `AccessibilityState` which provides `type`, `name`, `value`, and `identifier`. All those properties can be used to identify every accessibility feature based on the type, name, value, or identifier.

The `AccessibilitySnapshot` class has a method `toDictionary` that returns a dictionary of all tracked accessibility objects. Values (based on the example configuration) will be returned as:

```json
{
    "values": {
        "bold_text": true,
        "button_shapes_enabled": false,
        "font_scalling": 1.25,
        "reduce_motion": false,
        "voice_over": true
    }
}
```

#### Accessibility monitor

**AccessibilityKit** also provides a user interface for observing changes. To be able to instantiate the view controller, use the method; `AccessibilityKit.shared.presentAccessibilityMonitor(on:)`.

### Getting started

To add **AccessibilityKit** to your project, install the library via CocoaPods as 
instructed above. 

#### Getting current state

To get the latest state of accessibility features, there is no need to define **AccessibilityKit**. You can use a method for this anytime.

```swift
let snapshot = AccessibilityKit.shared.currentAccessibilitySnapshot(
    for: [
        AccessibilityTrackingObject(type: .boldText),
        AccessibilityTrackingObject(
            type: .fontScale, 
            customIdentifier: "font_scalling"
        )
    ]
)
```

#### Observing changes through the app lifecycle

If there is a need to observe accessibility feature changes, the method above is not enough. Instead of that, **AccessibilityKit** should be configured first.

To do that, use  `AccessibilityKit.shared.configureAccessibilityTracking(with:)` in the `AppDelegate`'s method `application(_:didFinishLaunchingWithOptions:)` to configure tracking for the app lifecycle.

```swift
AccessibilityKit.shared.configureAccessibilityTracking(
    with: AccessibilityTrackingConfiguration(
        fetchType: .continuous,
        objects: [
            AccessibilityTrackingObject(type: .boldText),
            AccessibilityTrackingObject(
                type: .buttonShapes, 
                customIdentifier: "button_shapes_enabled"
            ),
            AccessibilityTrackingObject(
                type: .fontScale, 
                customIdentifier: "font_scalling"
            ),
            AccessibilityTrackingObject(type: .reduceMotion),
            AccessibilityTrackingObject(type: .voiceOver),
        ]
    )
)
```

After that, the observing method can be used afterward to get the latest accessibility feature states.

```swift
AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
    ...
}
```

Also, when **AccessibilityKit** is configured for active tracking, the activity monitor can be used and shown when needed.

```swift
AccessibilityKit.shared.presentAccessibilityMonitor(on: viewController)
```

## Authors

Nikola Majcen, nikola.majcen@infinum.com

## License

AccessibilityKit is available under the MIT license. See the [license](LICENSE.md) for more information.

## Credits

Maintained and sponsored by [Infinum](http://www.infinum.com).

![Infinum logo](https://cloud.githubusercontent.com/assets/1422973/24369980/9c36b0a6-12da-11e7-898a-b711ed7ca52f.png)
