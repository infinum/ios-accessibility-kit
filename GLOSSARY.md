# AccessibilityKit

A library that reads the accessibility features a user has turned on, reports them to the app as they change, and shows them in an in-app debugging UI, the kit.

## Language

### Tracking

**Feature**:
One accessibility setting the library can read, such as VoiceOver, Bold text or the font scale.
_Avoid_: option, preference

**Tracking configuration**:
The features an app asks to follow, and whether they are reported once or on every change.
_Avoid_: setup, tracking settings

**Tracking object**:
One entry in a tracking configuration: a feature, optionally reported under a custom identifier and corrected by a transform.

**Fetch type**:
Whether tracking reports once (initial) or on every change (continuous).
_Avoid_: mode

**Identifier**:
The name a feature's value is reported under: the feature's default one, or a custom identifier the app chose.
_Avoid_: key

**Transform**:
An app-supplied correction applied to a feature's value before it is reported, such as turning a font scale into "large text is on".
_Avoid_: mapper, converter

**Snapshot**:
The values of every tracked feature at one moment, after their transforms.
_Avoid_: reading, state dump

**State**:
One feature's entry in a snapshot: its feature, name, identifier and value.

**Observation**:
An app's registration to receive snapshots, which lasts until it is cancelled or released.
_Avoid_: subscription

**Tracker**:
The library's tracking engine: it holds the tracking configuration, follows changes, records history and delivers snapshots to observations and to the kit.
_Avoid_: monitor

**Delivery**:
Handing a snapshot to the observations and the kit that were registered when it was taken.

**Recorded history**:
A feature's system values this session, before any transform: the value at launch or when tracking started, then each change.
_Avoid_: raw history, log

**Displayed history**:
A feature's recorded history as the app reports it: each value through the transform, with changes the transform folds together merged.
_Avoid_: transformed history

### The kit

**Kit**:
The in-app debugging UI, opened over the app, whose home lists its tools.
_Avoid_: debug menu, overlay

**Tool**:
One thing the kit offers from its home. The Monitor is the first; Audit, Inspect, Overlays and Text size are planned.

**Monitor**:
The kit's tool that lists every tracked feature with its value, its changes and its history.
_Avoid_: using "monitor" for the tracker

**Entry point**:
A way people open the kit: the floating button or a shake of the device.
_Avoid_: trigger

**Tracking status**:
What the kit says about tracking: not set up, live, or a one-time snapshot.

**Change mark**:
The highlight a Monitor row shows when its feature changes while the kit is open.

### Example app

**Test bench**:
The Example app: one product screen built for the kit's tools to examine.

**Planted issue**:
An accessibility problem put on the test bench on purpose, for the kit's tools to find.
