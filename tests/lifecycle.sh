#!/usr/bin/env bash
# Run on an isolated Termux test setup. Restarts its muxtops desktop.
set -euo pipefail
state=${XDG_STATE_HOME:-$HOME/.local/state}/muxtops

desktop stop
desktop start &
a=$!
desktop start &
b=$!
wait "$a"
wait "$b"
[[ $(pgrep -xc Xvnc) == 1 ]]
[[ $(pgrep -xc openbox) == 1 ]]
[[ $(pgrep -xc tint2) == 1 ]]
desktop status

desktop stop
if desktop status; then echo 'Stopped desktop reported running' >&2; exit 1; fi
for name in Xvnc openbox tint2 dbus-daemon; do
    if pgrep -x "$name" >/dev/null; then echo "Leaked process: $name" >&2; exit 1; fi
done

# An old PID must not let stop kill an unrelated process.
sleep 30 &
sentinel=$!
trap 'kill "$sentinel" 2>/dev/null || true' EXIT
printf '%s 0\n' "$sentinel" > "$state/session.pid"
desktop stop
kill -0 "$sentinel"
rm -f "$state/session.pid"
kill "$sentinel"
wait "$sentinel" 2>/dev/null || true
trap - EXIT

desktop start
desktop status
printf 'Lifecycle, concurrency, cleanup and stale PID protection: PASS\n'
