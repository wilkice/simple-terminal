# Simple Terminal

A minimal Apple Silicon Swift/AppKit host for full embedded libghostty: one
window, one interactive login `/bin/zsh` in your home directory, basic keyboard
input, resize/focus forwarding, and cleanup on window close or shell exit.
The [specification](.scratch/simple-terminal/map.md) defines the narrow scope.

## Build on GitHub Actions

Push this repository to GitHub. The **Build macOS demo** workflow runs on pushes,
pull requests, or manually from Actions. It uses the `macos-15` arm64 runner,
checks for Metal tools (downloads the Xcode component if needed), builds the pinned
full libghostty XCFramework, compiles the host, and ad hoc signs the `.app`.
No Apple developer account or signing secrets are required.

Download the **SimpleTerminal-arm64** artifact from the completed workflow run.
It contains `SimpleTerminal-arm64.zip` and `toolchain.txt`, which records the
runner's exact macOS, Xcode, SDK, Swift, Zig, and Ghostty versions. Extract the
inner ZIP on your Apple Silicon Mac and launch:

```sh
ditto -x -k SimpleTerminal-arm64.zip ./demo
open './demo/Simple Terminal.app'
```

Your local Mac does not need Xcode to run the artifact. This is an ad hoc signed
personal demo, not a notarized distribution; macOS may require approval to open
it in System Settings → Privacy & Security.

The workflow uses GitHub's documented [arm64 macOS runner](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).
Metal component installation follows [Apple's instructions](https://developer.apple.com/documentation/Xcode/downloading-and-installing-additional-xcode-components).

## Optional local build

On a Mac with full Xcode and Metal tools:

```sh
bash scripts/prepare-dependency.sh
bash scripts/build-app.sh
open '.build/Simple Terminal.app'
```

If Xcode is not the selected developer directory, set `DEVELOPER_DIR` to its
`Contents/Developer` directory for those commands. Dependency preparation verifies
the pinned source and Zig archive checksums. Downloads/build caches stay in the
ignored `.dependencies/` directory; the app and ZIP stay in `.build/`.

With just Command Line Tools and the already downloaded pinned headers, check
the Swift/C API integration without building Metal or linking:

```sh
bash scripts/typecheck.sh
```

## Integration and verification

Follow [the integration walkthrough](docs/integration.md) for the actual host and
library ownership, callbacks, keyboard/resize forwarding, and teardown.

Local Swift typechecking against the pinned C header, shell syntax checking, and
Info.plist validation passed on 2026-10-16. Full linking and CI execution have
**not** been verified from this workspace; it has no GitHub remote. The earlier
local dependency build failed because Metal/Xcode are absent, as recorded in
[the build-gate history](docs/build-gate.md). The user authorized writing the host
and moving the build to CI on 2026-10-16.

After downloading the CI artifact, manually check:

1. Launch it and type `echo hello`; confirm `hello` and a usable prompt.
2. Resize the window and confirm the terminal follows the new dimensions.
3. Enter `exit`; confirm the app ends. Relaunch, close the window, and confirm
   the app and shell end (Activity Monitor can check the child process).

These runtime checks remain pending. The workflow checks compilation/linking,
resource packaging, and signature validity; it does not prove interactive behavior.
