# Immediate exit on startup — 2026-10-16

## Cause

The CI-built app launched its libghostty surface and immediately terminated when
the child process exited. The host supplied `exec /bin/zsh -il`, but the pinned
library's macOS `execCommand` already prefixes shell commands with `exec -l`.
That generated `exec -l exec /bin/zsh -il`, which fails with status 127:

```sh
/bin/bash --noprofile --norc -c 'exec -l exec /bin/zsh -il'
# /bin/bash: line 0: exec: exec: not found
```

The source fix supplies `/bin/zsh -il` without the extra `exec`.
Source: [pinned Exec.zig](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/termio/Exec.zig#L1942).

## Evidence and verification

The downloaded app's signature verified successfully. Its bundled CI record
reports arm64 macOS 15.7.9 (24G830), Xcode 16.4 (16F6), SDK 15.5, Swift 6.1.2,
Zig 0.16.0, and the specified Ghostty commit. These establish a successful
dependency/link build, but the original app did not pass runtime acceptance.

Normal launches exited with status 0 because the host deliberately terminates on
child exit. Unified libghostty logs showed `/usr/bin/login` starting, then the PTY
closing and an abnormal child exit. Initial sandboxed diagnostic launches instead
aborted in AppKit registration; repeating outside that sandbox reproduced the
actual immediate-exit symptom.

To isolate one variable without downloading or rebuilding dependencies, a
temporary copy of the downloaded app had only its command literal replaced with
`/bin/zsh -il` plus trailing padding (same binary length), then was ad hoc signed.
The user's original downloaded app was not modified. On this arm64 Mac:

- Original app failed `scripts/check-startup.sh` with immediate exit.
- Corrected temporary app remained open and displayed the normal home-directory
  shell prompt. Typing `echo hello` displayed `hello` and a usable prompt.
- Resizing via the title bar changed `stty size` from `49 179` to `35 112`.
- Typing `exit` ended the app with exit status 0.
- Relaunching and closing the window ended the app, login, and zsh processes;
  the previously recorded process IDs were all absent afterward.
- The same startup regression script passed on the corrected temporary app.

The temporary binary demonstrates the command correction against the real pinned
library. A fresh CI build of the changed Swift source is still required. No full
Ghostty source archive, Zig installation, or build cache was downloaded locally
for this diagnosis.

## Startup regression check

On an interactive Mac, run:

```sh
bash scripts/check-startup.sh '/path/to/Simple Terminal.app'
```

It fails if the actual app exits within five seconds and terminates the diagnostic
instance afterward. It catches this startup regression; it does not replace manual
input, resize, and normal cleanup checks. Run outside a restricted command sandbox
so AppKit can register with the window server.
