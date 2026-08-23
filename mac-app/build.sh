#!/bin/bash
# Builds CopyCopyCopy.app — an unsigned, local macOS menu bar app.
# Run: ./build.sh   (from inside mac-app/)
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="CopyCopyCopy"
BUNDLE="$APP_NAME.app"

echo "Building Swift executable (release)…"
swift build -c release

echo "Assembling $BUNDLE…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

cp ".build/release/${APP_NAME}Mac" "$BUNDLE/Contents/MacOS/${APP_NAME}Mac"
cp Info.plist "$BUNDLE/Contents/Info.plist"

if [ -f ../icons/icon128.png ]; then
  echo "Building AppIcon.icns from ../icons/icon128.png…"
  ICONSET=$(mktemp -d)/AppIcon.iconset
  mkdir -p "$ICONSET"
  for size in 16 32 64 128 256 512; do
    sips -z "$size" "$size" ../icons/icon128.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "Done: $(pwd)/$BUNDLE"
echo "Move it to /Applications, then double-click to launch."
echo "First launch: right-click → Open (unsigned build, Gatekeeper will warn once)."
