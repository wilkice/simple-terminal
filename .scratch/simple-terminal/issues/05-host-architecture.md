# Decide the native host and dependency boundary

Labels: wayfinder:grilling
Type: grilling
Status: resolved
Assignee: none
Parent: ../map.md
Blocked by: 01

## Question

What is the minimum native host and dependency boundary needed to demonstrate full-libghostty integration?

## Answer

Resolution — 2026-10-14

The user confirmed a small Swift/AppKit host with a thin pinned internal-API adapter, as described in [the authoritative spec](../map.md). Libghostty owns terminal processing, rendering, PTY, and shell execution. Host code supplies initialization, required callbacks/ticks, native view/surface creation, basic input/focus/size/scale forwarding, and cleanup. Excluded-feature callbacks use valid unsupported/deny behavior rather than adding features. Build feasibility is still unverified; this resolves the design boundary, not the build gate.
