#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="EyeCare"
PRODUCT_BINARY_NAME="EyeCareMenubar"
APP_DIR="$ROOT_DIR/dist/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE_PATH="$ROOT_DIR/resources/AppIcon.icns"
ICON_TARGET_PATH="$RESOURCES_DIR/AppIcon.icns"
MODULE_CACHE_DIR="$ROOT_DIR/.build/module-cache"

mkdir -p "$MODULE_CACHE_DIR"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
swift build \
    -c release \
    --package-path "$ROOT_DIR" \
    --disable-sandbox \
    -Xswiftc -module-cache-path \
    -Xswiftc "$MODULE_CACHE_DIR"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/.build/release/$PRODUCT_BINARY_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [[ ! -f "$ICON_SOURCE_PATH" ]]; then
    echo "Icon source not found: $ICON_SOURCE_PATH" >&2
    exit 1
fi
cp "$ICON_SOURCE_PATH" "$ICON_TARGET_PATH"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>EyeCare</string>
    <key>CFBundleExecutable</key>
    <string>EyeCare</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.eyecaremenubar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>EyeCare</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Packaged app bundle: $APP_DIR"
