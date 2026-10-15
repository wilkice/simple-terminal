#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
GHOSTTY="$ROOT/.dependencies/ghostty-291fd050b9e9c293c8adb6a140742649b7e42d3a"
KIT="$GHOSTTY/macos/GhosttyKit.xcframework/macos-arm64"
APP="$ROOT/.build/Simple Terminal.app"

[[ $(uname -m) == arm64 ]] || { echo 'Apple Silicon required.' >&2; exit 1; }
[[ -d "$KIT" ]] || { echo 'Run bash scripts/prepare-dependency.sh first.' >&2; exit 1; }
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp -R "$GHOSTTY/zig-out/share/." "$APP/Contents/Resources/"
[[ -d "$APP/Contents/Resources/ghostty/shell-integration/zsh" ]]
[[ -f "$APP/Contents/Resources/terminfo/78/xterm-ghostty" ]]
xcrun swiftc -swift-version 5 -O -target arm64-apple-macosx13.0 \
    -I "$KIT/Headers" "$ROOT/Sources/main.swift" \
    "$KIT/libghostty-internal.a" -lc++ \
    -framework AppKit -framework Carbon -framework CoreText \
    -framework CoreGraphics -framework QuartzCore -framework Metal \
    -framework IOSurface -framework IOKit -framework CoreVideo \
    -o "$APP/Contents/MacOS/SimpleTerminal"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
echo "$APP"
