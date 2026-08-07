# Configurable Middle-Click Triggers Design

## Goal

Let the user choose how MidClick triggers a middle-click action on Magic Mouse while preserving the existing lightweight menu-bar workflow.

## Trigger choices

MidClick supports exactly one active trigger at a time:

- `Center Click` — one finger in the center zone plus a physical Magic Mouse click.
- `Two-Finger Click` — exactly two active touches plus a physical click.
- `Three-Finger Click` — exactly three active touches plus a physical click.
- `Two-Finger Tap` — two fingers briefly touch and release without a physical click.
- `Three-Finger Tap` — three fingers briefly touch and release without a physical click.

`Center Click` remains the default for existing users.

## Menu UX

The status menu adds a `Trigger` submenu immediately below `Middle Click Enabled`. Each trigger is represented by a mutually exclusive checkmark. Selecting an item applies immediately and persists in `UserDefaults`.

## Architecture

### `MiddleClickTrigger`

A shared enum in `MidClickCore` provides stable raw values for persistence and classifies triggers as physical-click or tap triggers.

### Physical clicks

A `PhysicalClickRecognizer` evaluates the latest Magic Mouse touch snapshot when `leftMouseDown` arrives. It converts only when the selected physical trigger matches the active contact count/center-zone rule and the sample is fresh.

### Taps

A stateful `TapGestureRecognizer` consumes Magic Mouse contact frames. For two- and three-finger tap triggers it:

- begins when the first finger appears,
- requires the requested finger count to be reached within 120 ms,
- rejects gestures longer than 250 ms,
- rejects centroid movement greater than 0.04 normalized units,
- rejects any frame with more fingers than requested,
- is cancelled by a physical mouse click,
- emits only after all fingers are released.

A cancelled tap remains suppressed until all contacts are released, preventing a physical click from becoming a tap on release.

### Integration

`MagicTouchMonitor` continues to own private-framework contact acquisition and exposes a frame callback containing filtered Magic Mouse contacts. `EventTapManager` owns trigger selection, physical click conversion, tap recognition, cancellation, and middle-button emission.

## Persistence

The selected trigger is stored under `middleClickTrigger`. Unknown or missing values fall back to `centerClick`.

## Safety

- Only recognized Magic Mouse frames participate.
- Native left clicks are suppressed only when a physical trigger has matched and a replacement middle-button sequence is emitted.
- Tap triggers never suppress normal physical clicks.
- Disabling MidClick resets pending tap state.
- Switching trigger resets pending tap state.
- No single-finger tap trigger is provided because accidental activation risk is too high.

## Verification

Automated tests cover:

- all five trigger raw values and fallback assumptions,
- center/two-finger/three-finger physical matching,
- stale and ambiguous physical samples,
- valid two- and three-finger taps,
- timeout, excessive movement, excessive finger count, and physical-click cancellation.

Manual verification on a physical Magic Mouse covers each trigger, persistence after restart, menu checkmarks, and unchanged native left/right click behavior.
