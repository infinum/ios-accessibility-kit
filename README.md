# AccessibilityKit

## Description

**AccessibilityKit** is a simple library that gives developers the ability to track accessibility features enabled by the user in real-time (through the application lifecycle).

The main idea of the library is to give the developer an update whenever a user changes the accessibility features and gets the currently enabled accessibility features. It is important to specify which accessibility features should be tracked - can be only one or all of them, which creates a snapshot every time the change is made based on the tracked accessibility features.

This library currently supports the **Swift** programming language.

## Table of contents

* [Requirements](#requirements)
* [Getting started](#getting-started)
* [Usage](#usage)
* [Documentation](#documentation)
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

Upgrading from 1.x? See the [migration guide](MIGRATION.md).

## Usage

Three common tasks are below. The [documentation](#documentation) covers each one in full.

### Reading the current state

Ask for a snapshot of the features you care about. Tracking doesn't need to be configured first:

```swift
let snapshot = try AccessibilityKit.shared.currentAccessibilitySnapshot(
    for: [
        AccessibilityTrackingObject(type: .boldText),
        AccessibilityTrackingObject(type: .voiceOver)
    ]
)
```

Each feature is reported under a default identifier, such as `bold_text`, or under a `customIdentifier` you pass. A snapshot is `Encodable`, and `try snapshot.toDictionary()` converts it for sending onward.

### Observing changes

Configure tracking once, at launch:

```swift
do {
    let configuration = try AccessibilityTrackingConfiguration(
        fetchType: .continuous,
        objects: [
            AccessibilityTrackingObject(type: .boldText),
            AccessibilityTrackingObject(type: .voiceOver)
        ]
    )
    AccessibilityKit.shared.configureAccessibilityTracking(with: configuration)
} catch {
    assertionFailure("Invalid accessibility tracking configuration: \(error)")
}
```

Then observe:

```swift
observation = AccessibilityKit.shared.observeAccessibilityTracking { snapshot in
    // handle the snapshot
}
```

Keep `observation` in a property: releasing it ends the observation. The kit holds the completion until then, so capture the object that owns `observation` weakly, or neither is ever released. Snapshots are delivered on the main queue.

### Opening the kit

The kit shows the accessibility settings while your app runs. Its Monitor lists every tracked feature and marks the ones that changed since launch. It's a debugging aid, so turn on its entry points in debug builds only:

```swift
#if DEBUG
AccessibilityKit.shared.entryPoints = [.floatingButton, .shake]
#endif
```

To open it from code, call `AccessibilityKit.shared.present()`.

## Documentation

The full documentation is written in DocC and published on the [Swift Package Index](https://swiftpackageindex.com/infinum/ios-accessibility-kit/documentation). You can also browse it in Xcode with `Product` -> `Build Documentation`, or read the guides here on GitHub:

* [Getting the current snapshot](Sources/AccessibilityKit/AccessibilityKit.docc/Articles/GettingTheCurrentSnapshot.md): identifiers, correcting values, and encoding
* [Configuring continuous tracking](Sources/AccessibilityKit/AccessibilityKit.docc/Articles/ConfiguringContinuousTracking.md): fetch types, observations, and isolation
* [The kit and its Monitor](Sources/AccessibilityKit/AccessibilityKit.docc/Articles/TheAccessibilityMonitor.md): entry points, and showing the Monitor yourself
* [Migration guide](MIGRATION.md): upgrading from 1.x

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
