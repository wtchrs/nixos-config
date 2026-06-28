#!/usr/bin/env bash

# Provide advisory single-instance locking for niri-float-sticky.
# This only works for instances launched through this wrapper.

set -euo pipefail

script_name="${0##*/}"
bin="${NIRI_FLOAT_STICKY_BIN:-niri-float-sticky}"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/${bin##*/}.${UID}.lock"

if ! command -v -- "$bin" >/dev/null 2>&1; then
  printf "%s: command not found: %s\n" "$script_name" "$bin" >&2
  exit 127
fi

if ! command -v -- flock >/dev/null 2>&1; then
  printf "%s: command not found: flock\n" "$script_name" >&2
  exit 127
fi

# Open the lock file in read/write mode and assign its file descriptor to `lock_fd`.
exec {lock_fd}<>"$lock_file"

# Try to acquire an exclusive lock using `lock_fd` in non-blocking mode.
if ! flock -x -n "$lock_fd"; then
  exit 0
fi

exec "$bin"
