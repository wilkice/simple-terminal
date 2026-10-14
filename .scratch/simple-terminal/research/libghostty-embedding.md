# Libghostty embedding baseline

Research date: 2026-10-14. Source-only investigation; nothing compiled or run.

## Recommendation

Use commit `291fd050b9e9c293c8adb6a140742649b7e42d3a` as a **candidate pinned baseline**, with Zig 0.16.0 and an Apple Silicon macOS host with Xcode/Apple SDK tooling. The source version is 1.3.2-dev. This is not a proven reproducible build until the build gate passes. [Version and Zig requirement](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/build.zig.zon)

Full embedding is explicitly **libghostty-internal**: its header says the sole consumer is Ghostty’s macOS app, it is tailored to that app, and external users should use libghostty-vt. Therefore adopting it means accepting a vendored internal API and maintaining a thin adapter, not consuming a supported stable full-terminal SDK. This corrects the earlier overly broad recommendation. [API status](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/include/ghostty.h)

## Build baseline to verify

Candidate command on an arm64 Mac, derived from build options (not executed):

```sh
zig build -Doptimize=ReleaseFast -Dapp-runtime=none -Demit-xcframework=true -Demit-macos-app=false -Dxcframework-target=native
```

The full XCFramework builder emits `macos/GhosttyKit.xcframework`, containing the static library, `ghostty.h`, and its module map. Native selects the build host architecture; universal is the default if omitted. XCFramework emission also installs resources. Pin the checkout, Zig, and the exact Xcode version that passes the first build; no specific Xcode version was validated here. [XCFramework builder](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/build/GhosttyXCFramework.zig), [Build options](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/build/Config.zig), [Build graph](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/build.zig)

Do not substitute `libghostty-vt`: it has separate build products and headers; it supplies terminal processing rather than the full embedded app surface and process/renderer runtime. [Separate products](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/build.zig), [API boundary](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/include/ghostty.h)

## Ownership boundary

| Area | Library owns | Swift/AppKit host owns |
|---|---|---|
| Shell and PTY | Child creation, PTY I/O, reader thread, child-exit notification and teardown | Command/environment/working-directory policy; responding to exit/close callbacks |
| Rendering | Embedded terminal surface and renderer | NSView lifetime, focus, visibility, display identity, redraw/event integration |
| Input and IME | Terminal key encoding and preedit/text APIs | NSEvent translation, NSTextInputClient marked text, composition, key routing |
| Resize | Terminal resize processing | Pixel sizes and content-scale updates on window/display changes |
| Clipboard | Request/completion protocol | Pasteboard read/write and requested confirmation callbacks |
| Lifetime | App/surface internals | Initialize config/app; dispatch wakeups to app tick; retain callback userdata; free surfaces before app/config teardown |
| Resources | Shell integration and terminfo consumers | Bundle installed resources and ensure discovery in the custom app |

Sources: [PTY ownership](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/termio/Exec.zig); [C boundary](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/include/ghostty.h); [Reference host callbacks and ticks](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/macos/Sources/Ghostty/Ghostty.App.swift); [AppKit input, IME, resize reference](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/macos/Sources/Ghostty/Surface%20View/SurfaceView_AppKit.swift); [Embedded runtime](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/apprt/embedded.zig).

The shell integration path explicitly disables integration when resources cannot be found, and derives terminfo locations relative to the resource tree. Copying only the binary/framework is insufficient as a packaging assumption. [Resource consumption](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/termio/Exec.zig)

## Decision implications and remaining verification

The source establishes a feasible embedding route and the host responsibilities. Before implementation commitment, require an arm64 compile/link smoke test, one interactive zsh surface, resize/IME/clipboard checks, clean child exit, and resource discovery in the actual app bundle. Exact deployment target, Xcode pin, Apple framework linkage, signing requirements, and custom-bundle resource discovery remain build-gate details, not verified facts. OSC 7501 exposure is investigated separately.

Local-only deviation: this workspace has no Git repository or remote. Findings remain here; no research branch was created or pushed.
