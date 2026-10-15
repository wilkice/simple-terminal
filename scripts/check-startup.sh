#!/bin/bash
# Run on an interactive Mac: catch an app that exits before a shell is usable.
set -euo pipefail
APP=${1:?Usage: bash scripts/check-startup.sh '/path/to/Simple Terminal.app'}
"$APP/Contents/MacOS/SimpleTerminal" &
APP_PID=$!
cleanup() {
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
}
trap cleanup EXIT
sleep 5
if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo 'FAIL: app exited during startup before a usable shell could remain open.' >&2
    exit 1
fi
echo 'PASS: app remained running for five seconds. Check input/resize/close manually.'
