#!/bin/bash
# CONTAINMENT — build script. Produces build/containment and (with --app) Containment.app
set -e
cd "$(dirname "$0")"
mkdir -p build

echo "Compiling CONTAINMENT…"
swiftc -O -whole-module-optimization -o build/containment source/*.swift

echo "Rendering app icon…"
./build/containment --icon build/icon.icns >/dev/null
iconutil -c icns build/Containment.iconset -o build/Containment.icns

if [ "$1" == "--app" ]; then
  APP="build/Containment.app"
  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cp build/containment "$APP/Contents/MacOS/Containment"
  cp build/Containment.icns "$APP/Contents/Resources/Containment.icns"
  cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Containment</string>
  <key>CFBundleDisplayName</key><string>CONTAINMENT</string>
  <key>CFBundleExecutable</key><string>Containment</string>
  <key>CFBundleIdentifier</key><string>local.containment.game</string>
  <key>CFBundleIconFile</key><string>Containment</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
  codesign --force --sign - "$APP" 2>/dev/null || true
  echo "Built $APP — double-click it, or: open $APP"
else
  echo "Built build/containment — run it with: ./build/containment"
fi
