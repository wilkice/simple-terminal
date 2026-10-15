# First dependency build attempt

Date: 2026-10-14 (Asia/Shanghai). Status: blocked, not a verified integration.

Update on 2026-10-16: the user authorized writing the minimal Swift host and
moving the full build to GitHub Actions without installing local Xcode. The host
now passes local typechecking against the pinned header; CI/link/runtime checks
remain pending. The observations below describe the original attempt, before the
host existed. See [current build/run instructions](../README.md).

## Observed environment

| Item | Observed value |
| --- | --- |
| Hardware architecture | `arm64` |
| macOS | `27.0.1`, build `26A434` |
| Selected developer directory | `/Library/Developer/CommandLineTools` |
| SDK (`xcrun --show-sdk-version`) | `27.0` |
| Swift | Apple Swift `6.4`, `swiftlang-6.4.0.34.1`, clang `2100.3.34.1` |
| Zig (downloaded and executed) | `0.16.0` |
| Ghostty source | `291fd050b9e9c293c8adb6a140742649b7e42d3a`, `1.3.2-dev` |
| Xcode | Unavailable; `xcodebuild -version` requires full Xcode |

## Command and failure

Downloaded the pinned source archive and Zig release, verified Zig against the
official download index, and ran from the Ghostty checkout:

```sh
ZIG_GLOBAL_CACHE_DIR=/Users/darcy/code/simple-terminal/.dependencies/zig-cache \
  ../zig-aarch64-macos-0.16.0/zig build \
  -Doptimize=ReleaseFast -Dapp-runtime=none \
  -Demit-xcframework=true -Demit-macos-app=false -Dxcframework-target=native
```

The build reported this failure in `metal Ghostty (Ghostty.ir)`:

```text
xcrun: error: unable to find utility "metal", not a developer tool or in PATH
error: process exited with error code 72
```

The overall Zig build finished with exit code 1: 247 of 255 steps succeeded,
one step failed, and the remaining steps had transitive failures. No
`GhosttyKit.xcframework` was produced.

The failing command was `/usr/bin/xcrun -sdk macosx metal ... -c
src/renderer/shaders/shaders.metal -mmacos-version-min=13.0.0`. This is the
dependency's chosen minimum version, not a validated host deployment target.
Independent checks of `xcrun --find metal` and `xcrun --find metallib` also failed.

Upstream `src/build/MetallibStep.zig` invokes both tools.
`src/build/XCFrameworkStep.zig` invokes `xcodebuild -create-xcframework` after
library compilation, so Command Line Tools alone cannot complete this route.
No upstream patches or substitute terminal libraries were introduced.

## Acceptance outcomes

| Required check | Actual outcome |
| --- | --- |
| Build dependency, link, and launch local `.app` | Dependency attempted; Metal step failed. Linking and launch not attempted. |
| One window/shell; `echo hello` and usable prompt | Not executed; no host app. |
| Resize terminal | Not executed. |
| Window close / `exit` releases session and ends app | Not executed. |
| Explanation matches working code/build procedure | Preparation documented; integration handoff pending working host. |

## Next gate

Select a full Xcode installation containing Metal tools and rerun
`scripts/prepare-dependency.sh`. Record the exact passing Xcode/SDK and resolve any
further build failures before implementing the minimal host. This is a missing
toolchain prerequisite, not evidence that full libghostty cannot embed a surface.
Installing Xcode was not attempted. No exact passing toolchain, linking
requirements, signing requirements, or custom-bundle resource discovery have
been established.
