# MidClick Agent Guide

## Product rule

MidClick should remain a tiny native macOS utility. The primary promise is: a center physical click on Magic Mouse behaves as middle click.

## Engineering constraints

- Prefer Swift and Apple system frameworks.
- No backend, account system, telemetry, ads, or network dependency.
- Keep recognition logic separate from macOS/hardware integration.
- Never suppress a native click unless a replacement event will be emitted.
- Fail closed when touch data is missing, stale, ambiguous, or unsupported.
- `MultitouchSupport.framework` is private API; load it dynamically and isolate it behind `MagicTouchMonitor`.
- Avoid unrelated mouse-customization features until the core gesture is reliable.

## Verification

For logic changes run:

```bash
swift test
```

For macOS integration changes also manually verify:

1. Normal left click is unchanged outside the center zone.
2. Native secondary/right click is unchanged.
3. Center click generates button 3 behavior in Safari/Chrome/VS Code.
4. Holding center click produces a balanced middle down/up sequence.
5. Disabling MidClick immediately restores native behavior.
6. Removing Accessibility permission does not break ordinary clicking.
