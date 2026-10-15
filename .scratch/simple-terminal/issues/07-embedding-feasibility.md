# Verify the selected embedding route before implementation commitment

Labels: wayfinder:task
Type: task
Status: awaiting GitHub Actions build and manual runtime verification
Assignee: none
Parent: ../map.md
Blocked by: 05

## Question

Can the candidate pinned full library build and link on Apple Silicon and run one interactive zsh surface in a minimal Swift/AppKit host? Record the exact passing toolchain, commands, linking and required resource setup. Verify only the minimum checks in [the authoritative spec](../map.md): command input/output, resizing, and app/session cleanup. Do not add IME, clipboard, scrollback controls, production features, or OSC 7501. If substantial patches or new subsystems are required, record the blocker and revisit the route rather than expanding scope.

## Attempt on 2026-10-14

The pinned dependency build ran with Zig 0.16.0 on arm64 macOS 27.0.1. It failed
at Metal shader compilation because the selected Command Line Tools do not
provide `metal`/`metallib`. XCFramework packaging also requires full Xcode.
No host implementation or runtime checks followed this failed gate. See
[the evidence and retry procedure](../../../docs/build-gate.md) and
[dependency preparation](../../../scripts/prepare-dependency.sh).

## Route update on 2026-10-16

The user requested the host implementation now and will build through GitHub
Actions instead of installing Xcode locally. The minimal host and CI workflow
are written. Local Swift typechecking passes against the pinned header; full
build/link and all interactive checks remain pending the first CI artifact.
See [current instructions](../../../README.md).
