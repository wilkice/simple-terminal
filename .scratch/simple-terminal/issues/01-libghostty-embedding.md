# Establish a reproducible libghostty embedding baseline

Labels: wayfinder:research
Type: research
Status: resolved
Assignee: darcy
Parent: ../map.md
Blocked by: none

## Question

Which exact upstream revision, toolchain, build outputs, and native embedding APIs provide a reproducible full-libghostty baseline for an arm64 macOS app? Identify ownership of shell/PTY lifecycle, rendering, input/IME, clipboard, resizing, resources, and shutdown; document host responsibilities and unsupported assumptions. Distinguish full embedding from libghostty-vt. Recommend a baseline with primary-source evidence, and separate source verification from anything actually built or tested.

## Answer

Resolution comment — 2026-10-14

Source investigation establishes candidate commit `291fd050b9e9c293c8adb6a140742649b7e42d3a`, Zig 0.16.0, the native GhosttyKit XCFramework route, and host/library ownership. Full embedding is an internal API, so the route requires accepting maintenance of a pinned adapter. Build reproducibility remains explicitly untested and must be an acceptance gate. See [Libghostty embedding baseline](../research/libghostty-embedding.md) for evidence, command, and limitations. Local-only research: no repository or remote exists to create/push a branch.
