#!/bin/bash
# Prepare the pinned full libghostty; this does not build the Swift host.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEPS="$ROOT/.dependencies"
GHOSTTY_REV=291fd050b9e9c293c8adb6a140742649b7e42d3a
GHOSTTY_SHA=f35b464f1aee22ffda9f6359038b9ad18a784342b4a4fa1cb97a79fb9ade79a4
ZIG_VERSION=0.16.0
ZIG_SHA=b23d70deaa879b5c2d486ed3316f7eaa53e84acf6fc9cc747de152450d401489

if [[ $(uname -s) != Darwin || $(uname -m) != arm64 ]]; then
    echo 'This demo requires an Apple Silicon Mac.' >&2
    exit 1
fi

# Command Line Tools alone cannot compile Metal or package an XCFramework.
if ! xcodebuild -version || ! xcrun -sdk macosx --find metal || ! xcrun -sdk macosx --find metallib; then
    echo 'Full Xcode and its Metal tools are required. Select them with DEVELOPER_DIR and retry.' >&2
    exit 1
fi

mkdir -p "$DEPS"
download() {
    local url=$1 archive=$2 checksum=$3
    if [[ ! -f "$archive" ]]; then
        curl --fail --location --retry 2 "$url" -o "$archive.part"
        mv "$archive.part" "$archive"
    fi
    printf '%s  %s\n' "$checksum" "$archive" | shasum -a 256 -c -
}

download "https://codeload.github.com/ghostty-org/ghostty/tar.gz/$GHOSTTY_REV" "$DEPS/ghostty.tar.gz" "$GHOSTTY_SHA"
download "https://ziglang.org/download/$ZIG_VERSION/zig-aarch64-macos-$ZIG_VERSION.tar.xz" "$DEPS/zig.tar.xz" "$ZIG_SHA"

if [[ ! -d "$DEPS/ghostty-$GHOSTTY_REV" ]]; then
    tar -xzf "$DEPS/ghostty.tar.gz" -C "$DEPS"
fi
if [[ ! -d "$DEPS/zig-aarch64-macos-$ZIG_VERSION" ]]; then
    tar -xJf "$DEPS/zig.tar.xz" -C "$DEPS"
fi

ZIG="$DEPS/zig-aarch64-macos-$ZIG_VERSION/zig"
[[ $("$ZIG" version) == "$ZIG_VERSION" ]]
export ZIG_GLOBAL_CACHE_DIR="$DEPS/zig-cache"
cd "$DEPS/ghostty-$GHOSTTY_REV"
"$ZIG" build -j2 -Doptimize=ReleaseFast -Dapp-runtime=none \
    -Demit-xcframework=true -Demit-macos-app=false -Dxcframework-target=native

echo "Full libghostty: $PWD/macos/GhosttyKit.xcframework"
echo "Runtime resources: $PWD/zig-out/share"
