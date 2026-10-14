# Verify the selected embedding route before implementation commitment

Labels: wayfinder:task
Type: task
Status: open
Assignee: none
Parent: ../map.md
Blocked by: 05

## Question

Can the candidate pinned full library build and link on Apple Silicon and run one interactive zsh surface in a minimal Swift/AppKit host? Record the exact passing toolchain, commands, linking and required resource setup. Verify only the minimum checks in [the authoritative spec](../map.md): command input/output, resizing, and app/session cleanup. Do not add IME, clipboard, scrollback controls, production features, or OSC 7501. If substantial patches or new subsystems are required, record the blocker and revisit the route rather than expanding scope.
