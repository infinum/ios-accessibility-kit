# AccessibilityKit

## About

**AccessibilityKit** is a simple library that gives developers the ability to track accessibility features enabled by the user in real time (through the application lifecycle).

The main idea of the library is to give the developer an update every time when a user changes the accessibility features, as well as getting the currently enabled accessibility features. It is important to specify which accessibility features should be tracked - can be only one or all of them, which then creates a snapshot every time the change is made based on the tracked accessibility features.

This library currently supports **Swift** programming language.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS 10 and above
* Xcode 10 and above

## Installation

AccessibilityKit is available through [CocoaPods](https://cocoapods.org) and [Swift Package Manager](https://www.swift.org/package-manager/).

To install it via Cocoapods, simply add the following line to your Podfile:

```ruby
pod 'AccessibilityKit'
```

## Usage

### Features

In this chapter, some of the most important pieces of the library will be introduced.
`AccessibilityKit` is the main class used to setup the *AccessibilityKit* library itself. It is defined as a singleton and it be used in a different ways.

#### Accessibility state

This library gives you an easy way to get the current state of the accessibility features on a device. The method `currentAccessibilitySnapshot(for:)`  returns a snapshot of a type `AccessibilitySnapshot` which contains all the neccessary information about the state of accessibility features on a current device. To configure which states will be returned, just pass an array of values of a type `AccessibilityTrackingObject`.

#### Configuration

To be able to configure a moreis configured via method `configureAccessibilityTracking(with:)`.

To configure the `AccessibilityKit` and its tracking, you should use the method `configureAccessibilityTracking(with:)` and provide a configuration object with all accessibility features that you want to track. The class used for that is `AccessibilityTrackingConfiguration`.

`AccessibilityTrackingConfiguration` class in its init method defines `fetchType` of type `AccessibilityFetchType` which can be `initial` or `continuous`. Based on the fetch type, values will be returned only one (`initial`), or it will continuously observe changes (`continuous`). The important here to note is; first snapshot of the accessibility states will be returned immediately after tracking is configured.

Another parameter needed for this configuration is an object of type `AccessibilityTrackingObject`. This class needs two parameters; first defines the accessibility feature you want to track - defined by `AccessibilityType`, and another parameter `customIdentifier` which is optional and defines custom identifier which will be used for that accessibility feature.

#### Observing changes

After the `AccessibilityKit` is configured, you can observe changes via the method `observeAccessibilityTracking(completion:)`. This method will return one or multiple snapshots based on the `fetchType` configured in the `AccessibilityTrackingConfiguration` init method.

An object returned in the completion is of a type `AccessibilitySnapshot` which returns an array of the states for every of the tracked accessibility features. Type of the object in the array is `AccessibilityState` which provides `type`, `name`, `value` and `identifier`. All those properties can be used to identify every accessibility feature based on the type, name, value, or identifier.

To get the result needed for tracking, `AccessibilitySnapshot` class has a method `toDictionary` which returns a dictionary of all tracked accessibility objects. Values will be returned as:

```json
{
    "values": {
        "key": value,
        ...
    }
}

```

#### Accessibility monitor

This library also provides a user interface for observing changes. To be able to instantiate the view controller, use the method; `loadViewController()` from the class `AccessibilityMonitorViewController`.

### Getting started

To add *Accessibility* to your project, install the library via CocoaPods as instructed above. After that, define *AccessibilityKit* configuration with mandatory parameters and call `AccessibilityKit.shared.configureTracking(with:)` in the `AppDelegate` method `application(_:didFinishLaunchingWithOptions:)`.

```swift
AccessibilityKit.shared.configureTracking(
    with: AccessibilityTrackingConfiguration(
        fetchType: .continuous,
        objects: [
            AccessibilityTrackingObject(type: .boldText),
            AccessibilityTrackingObject(type: .buttonShapes, customIdentifier: "button_shapes_enabled"),
            AccessibilityTrackingObject(type: .fontScale, customIdentifier: "font_scalling"),
            AccessibilityTrackingObject(type: .reduceMotion),
            AccessibilityTrackingObject(type: .voiceOver),
        ]
    )
)
```

## Authors

* Nikola Majcen, nikola.majcen@infinum.com

## License

AccessibilityKit is available under the MIT license. See the [license](LICENSE) file for more information.

## Credits

Maintained and sponsored by [Infinum](http://www.infinum.com).
