# Minimal libghostty integration demo

Status: agreed — ready for implementation when requested

## Goal

A very basic Apple Silicon macOS terminal app whose sole purpose is to show how to integrate full libghostty. The result should make the integration process easy to follow. It is a disposable learning demo, not a general-purpose terminal product.

This file is the authoritative specification. On 2026-10-14, the user clarified that anything beyond demonstrating basic libghostty integration must not be implemented. That clarification supersedes the broader interaction checklist discussed earlier, including mandatory IME, clipboard, and scrollback features.

## Minimum behavior

- Launch one native window containing one libghostty terminal surface.
- Start one interactive `/bin/zsh` session in the user's home directory, using normal shell startup files.
- Focus the terminal so basic keyboard input reaches the shell and shell output is rendered.
- Forward window-size changes to the terminal surface.
- Close the app and release its surface/session when the window closes or the shell exits.

No settings interface, restart flow, or close-confirmation dialog is required.

## Integration structure

Use a small Swift/AppKit host and a thin adapter to the pinned full-libghostty API. Keep the integration readable; avoid abstractions that are unnecessary for the demo.

Libghostty owns terminal processing, the renderer, the PTY, and shell execution. The host owns only the glue needed to embed it:

1. Initialize libghostty and its configuration.
2. Supply the callbacks required by the pinned API, including wakeup/tick dispatch.
3. Create the native view and terminal surface, configuring the shell and working directory.
4. Forward basic keyboard input, focus, dimensions, and content scale.
5. Handle shell exit and release objects in the required order.

Required callbacks for excluded features should use the simplest valid unsupported/deny behavior supported by the API. Their existence does not authorize implementing those features. Do not add custom PTY handling or a renderer.

## Dependency and build

Use full embedded libghostty, not libghostty-vt. Full embedding uses an internal API; this demo accepts a pinned integration rather than requiring a stable external SDK.

The [existing source investigation](research/libghostty-embedding.md) identifies this candidate baseline:

- Ghostty commit `291fd050b9e9c293c8adb6a140742649b7e42d3a`.
- Zig 0.16.0.
- Native Apple Silicon GhosttyKit XCFramework, with a Swift/AppKit host.

These are source-investigated candidates, not a verified build. Exact Xcode/SDK versions, deployment target, linking requirements, and runtime resource discovery must be established during the minimal integration attempt. Do not invent successful results or silently substitute libghostty-vt.

Provide documented commands to prepare the dependency, build a local `.app`, and run it. Include the runtime resources required for this minimal session. No installer, distribution packaging, or signing workflow beyond what local execution requires.

First verify the dependency can build and link and a single surface can run zsh. Continue only with the integration glue needed for the minimum behavior. If the candidate cannot support this without substantial patches or additional subsystems, record the blocker and revisit the route rather than expanding scope.

## Learning handoff

Provide a short explanation that follows the actual integration code: build/link, initialization, callbacks and tick dispatch, surface creation, input/resize forwarding, and cleanup. Identify which responsibilities belong to the host and which belong to libghostty. Document only what the demo uses.

## Acceptance

The demo is complete when:

1. Documented commands build and launch it on an Apple Silicon Mac; exact passing dependency and toolchain versions are recorded.
2. One window opens with one shell; typing `echo hello` displays `hello` and returns to a usable prompt.
3. Resizing the window updates the terminal surface.
4. Closing the window or entering `exit` ends the app and releases the session.
5. The short integration explanation matches the code and build/run procedure.

Record actual outcomes for these checks. None has been executed yet. This is a manual smoke check, not a compatibility certification or a request for a broad test suite.

## Excluded implementation

- Dedicated IME integration, clipboard functionality, scrollback controls, selection features, custom shortcuts, or appearance/settings controls.
- OSC 7501, status bars, record lists, or other program-status interfaces.
- Tabs, splits, session restoration, notifications, SSH management, or additional windows/sessions.
- Production hardening, a compatibility matrix, comprehensive failure UI, long-term patch maintenance, installers, or public distribution.
- Windows, Linux, Intel support, a new terminal engine, or a custom renderer.

Behavior that libghostty already supplies may be present naturally; it does not need extra host implementation or acceptance coverage. Basic error reporting needed to diagnose integration failures belongs in the build/run explanation or console, not a new user-facing subsystem.

## Supporting records

Earlier tracker questions and research recommendations are historical where they exceed this spec:

- [Embedding baseline](issues/01-libghostty-embedding.md): source investigation only.
- [Compatibility contract](issues/03-compatibility-contract.md): narrowed to the manual acceptance checks above.
- [Host architecture](issues/05-host-architecture.md): narrowed to minimum integration glue.
- [Embedding feasibility](issues/07-embedding-feasibility.md): minimal build/link/shell verification remains unperformed.
- [Implementation handoff](issues/06-implementation-handoff.md): scoped to the learning handoff above.
- [OSC 7501](issues/02-osc7501-integration.md) and [status presentation](issues/04-status-presentation.md): outside scope.

This workspace has documentation only and no Git repository or remote. This interview edits the specification; it does not authorize starting app implementation. The user confirmed shared understanding of this narrowed contract on 2026-10-14. No product-design questions remain open; technical feasibility remains unverified.
