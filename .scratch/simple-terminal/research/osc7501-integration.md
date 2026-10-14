# OSC 7501 integration research

Investigated 2026-10-14. Source-only review; no build or runtime conformance test.

## Answer

Full embedded libghostty does **not** expose working OSC 7501 support at the reviewed revision. Its shared parser supports reports, but its application stream handler explicitly ignores `.program_status`. A small maintained upstream patch is required for the proposed native app. This corrects the earlier assumption that existing parser support would imply a usable host callback.

Reviewed upstream main commit: `291fd050b9e9c293c8adb6a140742649b7e42d3a`, committed 2026-10-14 08:49:13 UTC. This is a research reference, not yet the application's selected dependency pin. [Commit](https://github.com/ghostty-org/ghostty/commit/291fd050b9e9c293c8adb6a140742649b7e42d3a)

## Verified integration boundary

- `src/terminal/osc/parsers/program_status.zig` defines `Command`, `Report`, `query_reply`, `readOption`, and `writeText`. It validates individual reports; it explicitly delegates record storage to consumers. Its tests cover duplicate keys, malformed pairs, base64, UTF-8, controls, limits, IDs, and state-specific fields. Tests were read, not executed. [Parser source](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/terminal/osc/parsers/program_status.zig)
- In full embedded Ghostty, `src/termio/stream_handler.zig` places `.program_status` under `// Unimplemented` and performs no action. This path therefore neither maintains records nor answers detection requests. `fullReset` and `semanticPrompt` are separate handlers that an integration can extend. [Application stream handler](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/termio/stream_handler.zig#L386)
- The public application header exposes `ghostty_runtime_action_cb` through `ghostty_runtime_config_s.action_cb`, but contains no program-status action or record query API. It has child-exit and command-finished action payloads; those alone do not provide status reports or the required complete reset/prompt lifecycle. [Embedded C header](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/include/ghostty.h)
- The distinct VT handler, `src/terminal/stream_terminal.zig`, offers an `Effects.program_status` callback. Registering it enables detection replies through `write_pty`. Report storage must be copied before callback return. RIS produces a synthetic root `clear`; `semantic_prompt` and `reset` effects also exist. These are verified **Zig VT handler** facilities, not proof of availability in the full application C API. [VT handler](https://github.com/ghostty-org/ghostty/blob/291fd050b9e9c293c8adb6a140742649b7e42d3a/src/terminal/stream_terminal.zig#L213)

## Protocol baseline

The current specification is revision 0.4 (2026-10-10). Reports replace records rather than merge. IDs form a hierarchy for descendant clearing and nearest-ancestor `app` inheritance. Screen switches preserve records; RIS clears all; DECSTR preserves them. Prompt start (OSC 133 A) and attached-process exit remove working/blocked records, optionally idle, while done/error survive. Detection requires a fixed support reply; programs may emit without querying. Programs must emit reports themselves; there is no automatic discovery of their internal state.

Conformance must include malformed/duplicate pairs, unknown state/key handling, optional base64 padding, invalid UTF-8/control rejection, and whole-report atomicity. Limits: 4096 sequence bytes, 16-byte keys, 2048 decoded message bytes, 192 decoded title bytes, 32-byte app, and IDs up to 128 bytes/eight levels/32-byte segments. Support 64–256 records, evicting the least recently updated at capacity. UI text is untrusted plain text; disarm invisible directional formatting. [Specification](https://www.superlogical.com/rex/docs/build/program-status)

## Recommended patch design (proposal, not implemented)

Keep full libghostty responsible for PTY, parsing, rendering, and detection response writes. Extend its existing application stream handler to consume the already validated `Command` and send an owned, typed surface event through the normal mailbox/action route to the host. Add a C action payload for report data and lifecycle events, with documented ownership and callback lifetime. Copy strings before leaving parser scope; do not hand borrowed parser storage to Swift asynchronously.

Keep a bounded, per-surface record reducer in Swift, implementing replacement, inheritance, subtree clearing, eviction, and presentation selection. Emit prompt-start and RIS lifecycle events in stream order; consume the existing attached-child exit event. Verify ordering against queued reports before relying on the exit callback. Detection replies should be enabled only for a host that actually installs this integration. Reuse the parser's fixed reply constant; never echo report contents.

This is smaller than introducing a second PTY reader or reparsing the byte stream in Swift. It avoids choosing libghostty-vt just for its callback, which would change the rendering/process scope. The patch's actual action/mailbox types, ownership, threading, and build viability require a focused integration proof before finalizing architecture.

## Remaining decision inputs

- Confirm willingness to maintain this patch against a pinned upstream revision.
- Prove report → C callback → Swift UI, detection reply, prompt cleanup, reset, and exit ordering in a disposable integration prototype.
- Choose record capacity, idle retention, acknowledgement of completed records, and status priority in the UI ticket.
- Test ordinary zsh prompt markers and any specifically required emitting application; SSH/multiplexer propagation remains unverified.

## Workflow deviation

The workspace has no Git repository or remote. Findings are local Markdown; no throwaway research branch could be created or pushed. No PR, app implementation, or upstream changes were made.
