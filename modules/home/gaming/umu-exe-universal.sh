set -euo pipefail

app_name="umu-exe-universal"

# shellcheck source=/dev/null
. "@umuExeCommon@"

if [ "$#" -lt 1 ]; then
  die "usage: $app_name <file.exe|file.msi|file.bat> [arguments...]"
fi

target=$1
shift

if [ ! -e "$target" ]; then
  die "target does not exist: $target"
fi

normalize_refresh_rate() {
  awk '
    {
      value = $1 + 0
      if (value <= 0) {
        next
      }
      if (value > 1000) {
        value = value / 1000
      }
      printf "%.3f\n", value
      exit
    }
  '
}

detect_refresh_rate() {
  local refresh=""

  if command -v niri >/dev/null 2>&1; then
    refresh=$(
      niri msg -j outputs 2>/dev/null \
        | jq -r '[.. | objects | select(has("current_mode")) | .current_mode.refresh_rate? // empty][0] // empty' \
        | normalize_refresh_rate
    ) || refresh=""
    if [ -n "$refresh" ]; then
      printf '%s\n' "$refresh"
      return 0
    fi
  fi

  if command -v kscreen-doctor >/dev/null 2>&1; then
    refresh=$(
      kscreen-doctor -o 2>/dev/null \
        | awk 'match($0, /@[0-9.]+\*/) { value = substr($0, RSTART + 1, RLENGTH - 2); print value; exit }' \
        | normalize_refresh_rate
    ) || refresh=""
    if [ -n "$refresh" ]; then
      printf '%s\n' "$refresh"
      return 0
    fi
  fi

  if command -v xrandr >/dev/null 2>&1; then
    refresh=$(
      xrandr --current 2>/dev/null \
        | awk '/\*/ { for (i = 1; i <= NF; i++) if ($i ~ /\*/) { gsub(/[+*]/, "", $i); print $i; exit } }' \
        | normalize_refresh_rate
    ) || refresh=""
    if [ -n "$refresh" ]; then
      printf '%s\n' "$refresh"
      return 0
    fi
  fi

  printf '60\n'
}

fps_limit_for_refresh_rate() {
  awk -v refresh="$1" 'BEGIN { printf "%.2f\n", refresh - (refresh * refresh / 4096) }'
}

init_umu_exe_prefix_env
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

refresh_rate=$(detect_refresh_rate)
fps_limit=$(fps_limit_for_refresh_rate "$refresh_rate")
export MANGOHUD=1
export MANGOHUD_CONFIG="no_display,fps_limit=$fps_limit,vsync=2"

UMU_CONTAINER_NSENTER=$(detect_umu_nsenter)
export UMU_CONTAINER_NSENTER
run_umu_with_gamemode "$target" "$@"
