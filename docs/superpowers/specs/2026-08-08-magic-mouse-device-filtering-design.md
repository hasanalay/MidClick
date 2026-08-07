# Magic Mouse Device Filtering Design

## Goal

Ensure MidClick listens only to Apple Magic Mouse touch frames. Built-in trackpads and external Magic Trackpads must never participate in center-click recognition.

## Current problem

`MagicTouchMonitor` registers every device returned by `MTDeviceCreateList()`. On a MacBook with a Magic Mouse this commonly produces two active devices: the built-in trackpad and the Magic Mouse. Because both callbacks update the same latest-touch snapshot, whichever device produced the most recent frame can affect click recognition.

## Options considered

1. **Exclude built-in devices only.** Simple, but an external Magic Trackpad would still be accepted. Rejected.
2. **Identify by IORegistry product name only.** Better, but product strings are not guaranteed to be identical across generations/local OS changes. Too brittle by itself.
3. **Use IORegistry product ID plus product-name fallback.** Recommended. Match known Apple Magic Mouse product IDs and also accept a case-insensitive `Magic Mouse` product name as a compatibility fallback.

## Selected design

For each device from `MTDeviceCreateList()`:

1. Obtain its IOKit service using `MTDeviceGetService`.
2. Read the IORegistry `Product` and `ProductID` values, searching the device, children, and parents when needed.
3. Accept the device when either:
   - the product ID is a known Magic Mouse generation, or
   - the product string contains `Magic Mouse` case-insensitively.
4. Register the multitouch callback only for accepted devices.
5. Ignore all other devices completely.

Known product IDs used initially:

- `0x030D` — first-generation Magic Mouse
- `0x0269` — Lightning Magic Mouse
- `0x0323` — USB-C Magic Mouse

The product-name fallback keeps the implementation usable if Apple introduces another revision whose ID is not yet in the list.

## Runtime status

`MagicTouchMonitor.Status.active` will describe the selected Magic Mouse rather than a generic device count. The menu bar should display a status such as:

`Touch Input: Magic Mouse`

If no supported Magic Mouse is detected, the status should be explicit and center-click conversion must remain inactive rather than falling back to another multitouch device.

## Safety rules

- Never register a built-in trackpad as a fallback.
- Never use touch frames from an unidentified device.
- Preserve normal mouse clicks when no Magic Mouse touch sample is available.
- Keep all private-framework and IOKit device-identification code isolated inside `MagicTouchMonitor`.

## Verification

Automated:

- `swift build`
- `swift test`
- Add pure matching tests for known product IDs and product-name fallback where practical.

Manual on a MacBook + Magic Mouse:

1. Menu reports one selected Magic Mouse instead of `Active (2)`.
2. Touching the MacBook trackpad does not affect center-click behavior.
3. Center physical click on Magic Mouse still produces a middle click.
4. Normal left/right clicks remain unchanged.
5. Disconnecting the Magic Mouse makes touch input unavailable instead of switching to the trackpad.
