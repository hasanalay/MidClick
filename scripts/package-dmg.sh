#!/bin/bash
set -euo pipefail

APP_NAME="MidClick"
BUNDLE_ID="com.hasanalay.midclick"
VERSION="${VERSION:-0.1.0}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE_B64="$ROOT_DIR/packaging/AppIcon.jpg.base64"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SOURCE_ICON="$TMP_DIR/AppIcon.jpg"
ICONSET_DIR="$TMP_DIR/AppIcon.iconset"
DMG_STAGING="$TMP_DIR/dmg"

cd "$ROOT_DIR"

echo "→ Building release binary"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

if [[ ! -x "$BIN_DIR/$APP_NAME" ]]; then
  echo "Release binary not found: $BIN_DIR/$APP_NAME" >&2
  exit 1
fi

if [[ ! -f "$ICON_SOURCE_B64" ]]; then
  echo "App icon source not found: $ICON_SOURCE_B64" >&2
  exit 1
fi

echo "→ Preparing app icon"
/usr/bin/base64 -D < "$ICON_SOURCE_B64" > "$SOURCE_ICON"
mkdir -p "$ICONSET_DIR"

make_icon() {
  local pixels="$1"
  local output="$2"
  /usr/bin/sips -s format png -z "$pixels" "$pixels" "$SOURCE_ICON" --out "$ICONSET_DIR/$output" >/dev/null
}

make_icon 16   icon_16x16.png
make_icon 32   icon_16x16@2x.png
make_icon 32   icon_32x32.png
make_icon 64   icon_32x32@2x.png
make_icon 128  icon_128x128.png
make_icon 256  icon_128x128@2x.png
make_icon 256  icon_256x256.png
make_icon 512  icon_256x256@2x.png
make_icon 512  icon_512x512.png
make_icon 1024 icon_512x512@2x.png

rm -rf "$DIST_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

echo "→ Creating app bundle"
cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

echo "→ Creating DMG"
/usr/bin/hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$APP_NAME.dmg"

echo ""
echo "✓ Created:"
echo "  $APP_DIR"
echo "  $DIST_DIR/$APP_NAME.dmg"
