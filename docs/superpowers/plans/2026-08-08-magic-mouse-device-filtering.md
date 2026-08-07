# Magic Mouse Device Filtering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make MidClick consume touch frames only from an Apple Magic Mouse and explicitly reject built-in trackpads and external Magic Trackpads.

**Architecture:** Add a pure `MagicMouseDeviceMatcher` to `MidClickCore` so product-ID/name matching is deterministic and unit-testable. Keep IOKit/IORegistry access and private `MultitouchSupport.framework` symbols inside `MagicTouchMonitor`, which will resolve each multitouch device to an IOKit service, read identity properties, and register callbacks only for matching Magic Mouse devices.

**Tech Stack:** Swift 5.10+, Swift Package Manager, AppKit, CoreFoundation, IOKit, private `MultitouchSupport.framework`, XCTest.

## Global Constraints

- Never register a built-in trackpad as a fallback.
- Never use touch frames from an unidentified device.
- Match known Magic Mouse product IDs `0x030D`, `0x0269`, and `0x0323`.
- Accept a case-insensitive product-name containing `Magic Mouse` as a compatibility fallback.
- Preserve normal mouse clicks when no valid Magic Mouse sample exists.
- Keep private-framework and IOKit identification code isolated inside `MagicTouchMonitor`.

---

### Task 1: Pure Magic Mouse identity matcher

**Files:**
- Create: `Sources/MidClickCore/MagicMouseDeviceMatcher.swift`
- Create: `Tests/MidClickCoreTests/MagicMouseDeviceMatcherTests.swift`

**Interfaces:**
- Produces: `MagicMouseDeviceMatcher.isMagicMouse(productID: UInt32?, productName: String?) -> Bool`

- [ ] **Step 1: Write failing tests**

Cover all three known product IDs, case-insensitive `Magic Mouse` name fallback, and rejection of Magic Trackpad/unknown devices.

- [ ] **Step 2: Run `swift test` and confirm matcher tests fail because the type does not exist.**

- [ ] **Step 3: Implement the minimal matcher**

```swift
public enum MagicMouseDeviceMatcher {
    public static let knownProductIDs: Set<UInt32> = [0x030D, 0x0269, 0x0323]

    public static func isMagicMouse(productID: UInt32?, productName: String?) -> Bool {
        if let productID, knownProductIDs.contains(productID) { return true }
        return productName?.range(of: "Magic Mouse", options: .caseInsensitive) != nil
    }
}
```

- [ ] **Step 4: Run `swift test`; matcher and existing recognizer tests must pass.**

---

### Task 2: Filter MultitouchSupport devices via IOKit

**Files:**
- Modify: `Sources/MidClick/MagicTouchMonitor.swift`

**Interfaces:**
- Consumes: `MagicMouseDeviceMatcher.isMagicMouse(productID:productName:)`
- Produces: `MagicTouchMonitor.Status.active(name: String, productID: UInt32?)`

- [ ] **Step 1: Add the private `MTDeviceGetService` symbol binding**

```swift
private typealias MTDeviceGetService = @convention(c) (MTDeviceRef) -> UInt32
```

- [ ] **Step 2: Add IORegistry property readers inside `MagicTouchMonitor`**

Read `ProductID` as `CFNumber` and `Product` as `CFString`, checking the service itself and recursive parent/child search options. Return `nil` rather than guessing when metadata cannot be read.

- [ ] **Step 3: Filter before callback registration**

For each `MTDeviceCreateList()` device: obtain its service; resolve product ID/name; call `MagicMouseDeviceMatcher`; skip non-matches; only then call `MTRegisterContactFrameCallback` and `MTDeviceStart`.

- [ ] **Step 4: Change failure behavior**

If no Magic Mouse matches, set `.unavailable("No Magic Mouse was found")`. Do not fall back to any other multitouch device.

- [ ] **Step 5: Run `swift build` and `swift test`.**

---

### Task 3: Expose selected device in menu status

**Files:**
- Modify: `Sources/MidClick/AppDelegate.swift`

**Interfaces:**
- Consumes: `MagicTouchMonitor.Status.active(name:productID:)`

- [ ] **Step 1: Update status rendering**

Render `Touch Input: Magic Mouse` for a selected device and optionally append the product ID in hexadecimal for debug visibility, e.g. `Touch Input: Magic Mouse (0x0269)`.

- [ ] **Step 2: Run `swift build` and `swift test`.**

- [ ] **Step 3: Verify via GitHub Actions CI.**

Manual follow-up on the target Mac: confirm the menu no longer reports `Active (2)`, touching the MacBook trackpad does not influence recognition, and Magic Mouse center click still emits a middle click.
