#!/bin/bash
# Uses Command Line Tools and the downloaded headers; no Metal/Xcode needed.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
HEADERS="$ROOT/.dependencies/ghostty-291fd050b9e9c293c8adb6a140742649b7e42d3a/include"
MODULE="$ROOT/.build/headers"
mkdir -p "$MODULE" "$ROOT/.build/module-cache"
# Match the XCFramework's header-only module without the unrelated VT headers.
cp "$HEADERS/ghostty.h" "$HEADERS/module.modulemap" "$MODULE/"
xcrun swiftc -swift-version 5 -typecheck -target arm64-apple-macosx13.0 \
    -module-cache-path "$ROOT/.build/module-cache" -I "$MODULE" "$ROOT/Sources/main.swift"
