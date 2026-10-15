# Integration walkthrough

## Build and resources

`scripts/prepare-dependency.sh` downloads Ghostty commit
`291fd050b9e9c293c8adb6a140742649b7e42d3a` and Zig `0.16.0` and builds the native
full GhosttyKit XCFramework, using two compile jobs to limit memory on the runner.
This uses Ghostty's internal embedding API, not the separate libghostty-vt API.

`scripts/build-app.sh` uses `swiftc` to compile `Sources/main.swift` for
`arm64-apple-macosx13.0`. It imports the XCFramework's GhosttyKit header module
and links its combined `libghostty-internal.a`, C++ runtime, and Apple frameworks.
It copies upstream `zig-out/share` into `Contents/Resources`, retaining the
`ghostty/` and sibling `terminfo/` layout. It then ad hoc signs and verifies the
bundle. The deployment target and link command are source-derived and awaiting
the first CI build; they are not yet a proven passing configuration.

The GitHub workflow builds on `macos-15`, records exact toolchain versions, and
archives the signed app with `ditto` so bundle permissions survive artifact upload.

## Initialization and callbacks

`TerminalApp.start()` sets `GHOSTTY_RESOURCES_DIR` and `TERMINFO` to bundled paths
before `ghostty_init` snapshots the environment. It creates a default config,
finalizes it, and creates the embedded app with required runtime callbacks. It
does not load the user's Ghostty configuration files.

The wakeup callback may run on any thread. It dispatches `ghostty_app_tick` to
the main queue. `TerminalApp` remains alive for the whole application run, and
queued ticks check that the app handle still exists after termination starts.
The library owns terminal state, renderer threads, PTY I/O, and process execution.
The host owns the native window/view and dispatch/lifetime glue.

Actions for quitting, closing the window, and child exit schedule termination on
the main queue. Other optional actions return unsupported. Clipboard reads return
unsupported; confirmation requests are denied and writes are ignored. No clipboard
or IME integration is implemented.

## Surface and input

`TerminalView.createSurface` passes the NSView and callback userdata to
`ghostty_surface_new`, together with the home directory and `direct:/bin/zsh -il`.
The strings are valid throughout surface creation; the library copies them.
`-i` and `-l` request the normal interactive login shell startup files. The host
creates no PTY or process itself. `wait_after_command` is false so shell exit
closes the surface/session instead of leaving an exited prompt open.

The view forwards physical macOS keycodes, modifiers, unshifted codepoints, and
printable text. Control characters and function-key private-use characters are
excluded from text so libghostty can encode those keys. Key repeats and releases
use the corresponding library actions. This is basic direct keyboard input;
composed text input is outside the demo's scope.

Layout and backing changes forward content scale, pixel dimensions, and display
identity. App activation and key-window changes update app/surface focus. The
terminal becomes the first responder when its window opens. Libghostty attaches
and operates its Metal renderer on the supplied native view.

## Cleanup

Window close and library shell-exit callbacks terminate the application. Library
callbacks defer termination to avoid destroying a surface during its callback.
`applicationWillTerminate` frees the surface first, then the embedded app, then
the configuration. The NSView and callback owner remain alive throughout teardown.
Libghostty handles stopping its renderer, closing the PTY, and terminating/reaping
the child. Runtime verification of that behavior remains a manual acceptance check.
