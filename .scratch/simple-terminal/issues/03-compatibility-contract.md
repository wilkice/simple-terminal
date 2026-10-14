# Define the first-version compatibility contract

Labels: wayfinder:grilling
Type: grilling
Status: resolved
Assignee: none
Parent: ../map.md
Blocked by: none

## Question

What minimum behavior demonstrates basic full-libghostty integration?

## Answer

Resolution — 2026-10-14

The user confirmed the narrowed specification on 2026-10-14. Acceptance is limited to the checks in [the authoritative spec](../map.md): build/run, one shell accepting `echo hello`, resize forwarding, and app/session cleanup on window close or shell exit. Dedicated IME, clipboard, selection, scrollback controls, and broad compatibility coverage are not required. Earlier broader recommendations are superseded.
