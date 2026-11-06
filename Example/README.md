# Example app

The Example app is a test bench: one realistic product screen with four accessibility problems planted on purpose, so the kit's tools have something to find. The Monitor ships today; Audit, Inspect, Overlays and Text size, named in the table below, are planned tools. Everything else on the screen is built correctly, as the reference for what good looks like. It tracks every setting and turns on the kit button and shake.

| # | Planted issue | Found by |
|:--|:--------------|:---------|
| 1 | The heart button has no accessibility label, so VoiceOver says only "Button" | Audit, Inspect |
| 2 | The heart button's target is 32 × 32 pt | Audit, Overlays, Inspect |
| 3 | The delivery line's contrast is 2.7:1 (needs 4.5:1) | Audit |
| 4 | The size buttons are a fixed 32 × 32 pt, so their numbers clip from about AX2 | Audit, Overlays, Text size |

Each is marked `Planted issue N` in [`ProductView.swift`](AccessibilityKit/ProductView.swift); leave them in when cleaning up. The Example scheme has two launch arguments, off by default, to try the kit's other states: `-kitFetchType initial` (a one-time snapshot) and `-kitTrackNothing` (nothing tracked). The Example app needs iOS 17.
