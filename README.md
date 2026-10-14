# Simple Terminal

A disposable Swift/AppKit learning demo for full embedded libghostty, scoped by
[the specification](.scratch/simple-terminal/map.md).

**Blocked at the dependency build gate. No host app has been implemented.** The
first build attempt on 2026-10-14 failed because the selected developer tools lack
the Metal compiler. The candidate XCFramework also requires full Xcode. See
[the recorded attempt](docs/build-gate.md) for evidence and acceptance status.

## Prepare the dependency

Install full Xcode with Metal tools, then run from this directory, adjusting the
Xcode path if needed:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/prepare-dependency.sh
```

This downloads and verifies Ghostty commit
`291fd050b9e9c293c8adb6a140742649b7e42d3a` and Zig `0.16.0` into the ignored
`.dependencies/` directory. The script checks Xcode and Metal availability before
downloading. It builds native arm64 **full libghostty**, without changing upstream
sources. Archive checksums are pinned; Zig's checksum matches its published
download index. The Ghostty checksum was measured from the downloaded commit
archive. A mismatch stops preparation.

Expected outputs, pending a successful build:

- `.dependencies/ghostty-291fd050b9e9c293c8adb6a140742649b7e42d3a/macos/GhosttyKit.xcframework`
- The same checkout's `zig-out/share/` runtime resources, including Ghostty shell
  integration and terminfo. Preserve these for the eventual app bundle; discovery
  from the custom bundle remains to be verified.

## Remaining implementation

After the dependency builds, establish linking and resource discovery in a small
Swift/AppKit host, then verify one libghostty surface running `/bin/zsh` in the
user's home directory. Libghostty will own the renderer, PTY, terminal processing,
and shell execution. Host code should supply initialization, required callbacks
and main-thread wakeup/tick dispatch, native view/surface creation, basic keyboard
input, focus, pixel dimensions/content scale, and cleanup on window or shell exit.

There are no `.app` build or launch commands yet, no verified link flags or
deployment target, and no code-level learning handoff. Those depend on passing
the build/link/shell gate; speculative host code would bypass the spec's gate.
The acceptance boundary is the spec's manual smoke check, with no broad test suite.
