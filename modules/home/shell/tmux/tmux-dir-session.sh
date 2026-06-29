#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

TMUX_BIN="${TMUX_BIN:-tmux}"

if ! command -v "$TMUX_BIN" >/dev/null 2>&1; then
  printf 'error: tmux not found: %s\n' "$TMUX_BIN" >&2
  exit 127
fi

# Pass arguments to tmux if exist
if [[ $# -gt 0 ]]; then
  exec "$TMUX_BIN" "$@"
fi

if ! command -v jq >/dev/null 2>&1; then
  # Run tmux without session management if jq does not exist
  printf 'warning: jq not found; running tmux without directory session management\n' >&2
  exec "$TMUX_BIN"
fi

# === functions

getSessionList() {
  local output
  local status

  # Use tab as delimiter, can fail when session path contains tab
  if output=$("$TMUX_BIN" list-sessions -F '#{session_path}'$'\t''#{session_name}' 2>&1); then
    :
  else
    # Error handling
    status=$?

    if [[ "$output" == *"no server running"* || "$output" == error\ connecting\ to\ *"(No such file or directory)"* ]]; then
      printf '{"by_path":{},"names":{}}\n'
      return 0
    fi

    printf 'tmux list-sessions failed: %s\n' "$output" >&2
    return "$status"
  fi

  # Print as json format
  jq -Rnc '
    reduce inputs as $line (
      { by_path: {}, names: {} };
      ($line | index("\t")) as $i
      | if $i == null then
          .
        else
          ($line[:$i]) as $path
          | ($line[$i+1:]) as $name
          | .by_path[$path] //= $name
          | .names[$name] = true
        end
    )
  ' <<< "$output"
}

isSessionDup() {
  if [[ "$#" -lt 2 ]]; then
    printf 'usage: isSessionDup <sessions-json-object> <session_name>\n' >&2
    return 2
  fi

  local sessions="$1"
  local session_name="$2"

  jq -e --arg v "$session_name" '(.names // {})[$v] == true' <<< "$sessions" >/dev/null
}

mkSessionName() {
  if [[ "$#" -lt 2 ]]; then
    printf 'usage: mkSessionName <sessions-json-object> <directory>\n' >&2
    return 2
  fi

  local sessions="$1"
  local dir="$2"
  local base
  local session
  local n

  base=$(basename "$dir")

  # Fallback
  if [[ -z "$base" || "$base" == "/" ]]; then
    base="root"
  fi

  session=$base

  # Sanitize
  session=${session//$'\t'/_}
  session=${session//$'\n'/_}
  session=${session//$'\r'/_}
  session=${session// /_}
  session=${session//\//_}
  session=${session//:/_}
  session=${session##+(=)}
  session=${session##+(_)}
  session=${session%%+(_)}

  # Fallback
  if [[ -z "$session" ]]; then
    session="session"
  fi

  # Handle session name duplicate
  if isSessionDup "$sessions" "$session"; then
    n=1
    while isSessionDup "$sessions" "${session}-${n}"; do
      ((n++))
    done
    session="${session}-${n}"
  fi

  printf "%s" "$session"
}

# === main

dir="$(pwd -P)"

# Load session list
sessions=$(getSessionList)

# Get session name corresponding to `dir` from `sessions`
session=$(jq -r --arg v "$dir" '(.by_path // {})[$v] // empty' <<< "$sessions")

# Generate session if not existing
if [[ -z "$session" ]]; then
  session=$(mkSessionName "$sessions" "$dir")
  "$TMUX_BIN" new-session -d -s "$session" -c "$dir"
fi

# Switch or attach
if [[ -n "${TMUX:-}" ]]; then
  "$TMUX_BIN" switch-client -t "=$session"
else
  exec "$TMUX_BIN" attach-session -t "=$session"
fi
