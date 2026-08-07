# MidClick Architecture

## Goal

Turn a physical click performed with one finger in the center zone of an Apple Magic Mouse into a native macOS middle-button click while leaving normal left and right clicks unchanged.

## Input pipeline

```text
Magic Mouse touch surface
        │
        ▼
MagicTouchMonitor
(raw normalized contacts)
        │
        ▼
CenterClickRecognizer
(single fresh center contact?)
        │
        ├── no ──► keep original left click
        │
        ▼ yes
EventTapManager suppresses
original left down/up
        │
        ▼
MiddleClickEmitter
CGEvent otherMouseDown/up
button = center / #2
```

## Components

### `MidClickCore`

Pure recognition logic with no AppKit dependency. The center zone and touch freshness tolerance live here so they can be unit tested without hardware.

### `MagicTouchMonitor`

Dynamically loads `/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport` and registers contact-frame callbacks for available multitouch devices.

The private framework is deliberately loaded at runtime instead of statically linked. If Apple removes or changes the symbols, MidClick fails closed: normal mouse clicks continue to work and the menu reports touch input as unavailable.

### `EventTapManager`

Installs a Core Graphics event tap for left-button down/up events. A click is replaced only when `CenterClickRecognizer` accepts a fresh touch snapshot.

The original left-button event is suppressed only after the replacement decision has been made. The corresponding mouse-up event is also replaced, preventing a mismatched down/up sequence.

### `MiddleClickEmitter`

Posts `otherMouseDown` / `otherMouseUp` with `CGMouseButton.center` and button number `2` at the original pointer location.

### Menu bar shell

`AppDelegate` owns runtime lifecycle, user enable/disable state, Accessibility prompting, and health/status reporting.

## Permissions

A filtering event tap requires Accessibility permission. MidClick checks `AXIsProcessTrusted` and asks macOS to display the standard permission prompt when needed.

## Current device-identification limitation

`MTDeviceCreateList` can expose more than the Magic Mouse (for example a built-in trackpad). The MVP registers all available multitouch devices and requires a very recent single center contact at the exact moment a left click occurs.

Before a production release, device identification should be tightened so only Magic Mouse contact frames participate in recognition.

## Failure policy

Mouse input is infrastructure. The app must fail conservatively:

- no touch data -> preserve original click
- stale touch data -> preserve original click
- multiple contacts -> preserve original click
- event tap unavailable -> do not synthesize clicks
- private framework unavailable -> report unavailable and preserve native behavior
