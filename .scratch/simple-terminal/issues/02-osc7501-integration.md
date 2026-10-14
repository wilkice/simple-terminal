# Establish the OSC 7501 integration boundary

Labels: wayfinder:research
Type: research
Status: resolved
Assignee: darcy
Parent: ../map.md
Blocked by: none

## Question

Does current upstream full libghostty expose OSC 7501 reports, record state, detection replies, prompt cleanup, and reset behavior through the embedded C API? Identify exact revisions and symbols, compare behavior to the current protocol specification, and recommend the smallest integration boundary. If parsing exists without a usable host API, document the bridge or patch required rather than assuming a generic OSC callback. Capture conformance edge cases and application-emission limitations using primary sources; distinguish verified source behavior from runtime tests.

## Answer

Resolution comment — 2026-10-14

Full embedded libghostty at `291fd050b9e9c293c8adb6a140742649b7e42d3a` ignores parsed OSC 7501 commands and exposes no program-status C action. The VT Zig handler supports effects, which must not be confused with the full application API. Recommend a small typed report/lifecycle bridge patch, using the existing parser and PTY reply path with a Swift record reducer. Architecture acceptance and runtime proof remain separate decisions.

[Research findings and source references](../research/osc7501-integration.md). Source review only; tests not run. No Git repository or remote exists, so research is local-only rather than a pushed throwaway branch.
