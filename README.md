# MidClick

MidClick is a tiny native macOS utility that turns a physical click in the center area of an Apple Magic Mouse into a real middle-mouse-button click.

The project is intentionally small and local-first: no account, no analytics, no backend, and no Electron runtime.

## Status

Early MVP under active development.

## MVP goal

- Run as a menu bar utility.
- Read Magic Mouse touch contacts.
- Detect a center-area physical click.
- Suppress the original left click.
- Emit native middle-button down/up events.
- Let the user enable/disable the behavior from the menu bar.

## Technical direction

- Swift / AppKit
- Core Graphics event taps and synthetic mouse events
- Accessibility permission for event interception
- Dynamically loaded `MultitouchSupport.framework` for raw Magic Mouse touch contacts

> `MultitouchSupport.framework` is a private macOS framework. That makes direct distribution (signed/notarized download, and potentially Homebrew) a better fit than the Mac App Store.

## Development

The first implementation is built as a Swift Package so the core input pipeline can be compiled and tested before we add release packaging.

```bash
swift build
swift test
swift run MidClick
```

When first running the utility, macOS must grant Accessibility permission so MidClick can intercept and replace mouse events.

## License

MIT
