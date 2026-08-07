# Configurable Middle-Click Triggers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add five selectable Magic Mouse middle-click triggers with persistence, menu UI, physical-click matching, and robust two-/three-finger tap recognition.

**Architecture:** `MidClickCore` gains a stable `MiddleClickTrigger` enum plus pure/testable recognizers for physical-click and tap gestures. `MagicTouchMonitor` exposes Magic Mouse contact frames, while `EventTapManager` coordinates selected trigger state, tap cancellation, native click suppression, and middle-button emission. `AppDelegate` owns menu presentation and `UserDefaults` persistence.

**Tech Stack:** Swift 5.10, Swift Package Manager, AppKit, CoreGraphics, Foundation, MultitouchSupport private framework.

## Global Constraints

- Exactly one trigger is active at a time.
- Default trigger is `Center Click`.
- Tap thresholds: 120 ms finger-arrival, 250 ms total duration, 0.04 normalized centroid movement.
- Physical mouse clicks cancel pending tap gestures.
- A cancelled tap remains suppressed until all contacts are released.
- No single-finger tap trigger.
- Only recognized Magic Mouse frames may participate.
- Native left clicks are suppressed only when a physical trigger matches and a replacement middle-button sequence is emitted.

---

### Task 1: Trigger model and physical-click recognizer

**Files:**
- Create: `Sources/MidClickCore/MiddleClickTrigger.swift`
- Create: `Sources/MidClickCore/PhysicalClickRecognizer.swift`
- Create: `Tests/MidClickCoreTests/PhysicalClickRecognizerTests.swift`

**Interfaces:**
- Produces: `MiddleClickTrigger: String, CaseIterable, Sendable`
- Produces: `PhysicalClickRecognizer.shouldConvertClick(trigger:contacts:sampleAge:) -> Bool`

- [ ] **Step 1: Write failing tests** for center, two-finger, three-finger, tap-trigger rejection, and stale frames.
- [ ] **Step 2: Run `swift test`** and verify the new symbols are missing.
- [ ] **Step 3: Implement `MiddleClickTrigger`** with raw values `centerClick`, `twoFingerClick`, `threeFingerClick`, `twoFingerTap`, `threeFingerTap`, plus `displayName`, `isTap`, and `requiredFingerCount`.
- [ ] **Step 4: Implement `PhysicalClickRecognizer`** using the existing center-zone configuration for one-finger center click and exact active-contact counts for two-/three-finger click.
- [ ] **Step 5: Run `swift test`** and verify all physical recognizer tests pass.

### Task 2: Stateful tap recognizer

**Files:**
- Create: `Sources/MidClickCore/TapGestureRecognizer.swift`
- Create: `Tests/MidClickCoreTests/TapGestureRecognizerTests.swift`

**Interfaces:**
- Produces: `TapGestureConfiguration`
- Produces: mutable `TapGestureRecognizer.processFrame(contacts:timestamp:requiredFingerCount:) -> Bool`
- Produces: `TapGestureRecognizer.cancel()` and `reset()`

- [ ] **Step 1: Write failing tests** for valid two-/three-finger taps, late finger arrival, timeout, excessive movement, too many fingers, cancellation, and suppression-until-release.
- [ ] **Step 2: Run `swift test`** and verify failure because the recognizer does not exist.
- [ ] **Step 3: Implement the state machine** with idle/tracking/suppressed behavior, centroid tracking, 120 ms arrival limit, 250 ms total limit, 0.04 movement limit, and release-only emission.
- [ ] **Step 4: Run `swift test`** and verify all tap recognizer tests pass.

### Task 3: Feed contact frames into gesture coordination

**Files:**
- Modify: `Sources/MidClick/MagicTouchMonitor.swift`
- Modify: `Sources/MidClick/EventTapManager.swift`
- Modify: `Sources/MidClick/MiddleClickEmitter.swift`

**Interfaces:**
- `MagicTouchMonitor.onFrame: (([TouchContact], TimeInterval) -> Void)?`
- `EventTapManager.trigger: MiddleClickTrigger`
- `MiddleClickEmitter.click(at:)`

- [ ] **Step 1: Add a frame callback** invoked only after the Magic Mouse filter has accepted the device and the frame has been converted to `TouchContact` values.
- [ ] **Step 2: Add `click(at:)`** as a balanced middle-down/middle-up convenience method.
- [ ] **Step 3: Replace center-only handling** in `EventTapManager` with `PhysicalClickRecognizer` using the selected trigger.
- [ ] **Step 4: Feed frames to `TapGestureRecognizer`** only when the selected trigger is a tap trigger and MidClick is enabled.
- [ ] **Step 5: Cancel the tap recognizer on every physical left-button down**, and reset it when disabled or trigger changes.
- [ ] **Step 6: Emit tap middle-clicks on the main queue** at the current pointer location.

### Task 4: Menu and persistence

**Files:**
- Modify: `Sources/MidClick/AppDelegate.swift`

**Interfaces:**
- Persists `MiddleClickTrigger.rawValue` under `middleClickTrigger`.
- Updates `EventTapManager.trigger` immediately.

- [ ] **Step 1: Load persisted trigger** at startup; fall back to `.centerClick` for missing/unknown values.
- [ ] **Step 2: Add a `Trigger` submenu** under `Middle Click Enabled` with all five trigger names.
- [ ] **Step 3: Make items mutually exclusive** using represented raw values and checkmarks.
- [ ] **Step 4: Persist and apply selection immediately** when the user chooses a trigger.
- [ ] **Step 5: Refresh checkmarks** during normal menu-state refresh.

### Task 5: Final verification

**Files:**
- No additional production files required.

- [ ] **Step 1: Run `swift build`.** Expected: success.
- [ ] **Step 2: Run `swift test`.** Expected: all tests pass.
- [ ] **Step 3: Verify GitHub Actions on `main`.** Expected: Build and Test steps succeed.
- [ ] **Step 4: Manual Magic Mouse verification:** each physical trigger, each tap trigger, trigger switching, restart persistence, enable/disable behavior, and unchanged native left/right clicks.
