#!/bin/zsh
# Builds LidAwake.app and LidAwake-<version>.dmg into ./build.
set -e
cd "$(dirname "$0")"
VERSION=${VERSION:-1.0.0}
OUT=build
APP=$OUT/LidAwake.app
rm -rf "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Icon
swift make_icon.swift "$OUT/AppIcon.iconset"
iconutil -c icns "$OUT/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

# Universal binary (Apple Silicon + Intel)
swiftc -O -target arm64-apple-macos13 main.swift -o "$OUT/LidAwake-arm64"
swiftc -O -target x86_64-apple-macos13 main.swift -o "$OUT/LidAwake-x86_64"
lipo -create "$OUT/LidAwake-arm64" "$OUT/LidAwake-x86_64" -output "$APP/Contents/MacOS/LidAwake"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>LidAwake</string>
  <key>CFBundleDisplayName</key><string>LidAwake</string>
  <key>CFBundleIdentifier</key><string>io.github.thinhv.lidawake</string>
  <key>CFBundleExecutable</key><string>LidAwake</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 Thinh Vo</string>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"

# DMG with an Applications shortcut for drag-to-install
STAGE=$OUT/dmg
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "LidAwake" -srcfolder "$STAGE" -ov -format UDZO "$OUT/LidAwake-$VERSION.dmg" >/dev/null
rm -rf "$STAGE" "$OUT/AppIcon.iconset" "$OUT"/LidAwake-arm64 "$OUT"/LidAwake-x86_64
echo "Built $(pwd)/$OUT/LidAwake-$VERSION.dmg"
