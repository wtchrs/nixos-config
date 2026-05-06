set -euo pipefail

app_name="umu-exe-universal"
proton_name="@protonName@"
proton_path="@protonPath@"
game_id="umu-exe-universal"
prefix_default="$HOME/Games/umu/exe-universal"

die() {
  printf '%s: %s\n' "$app_name" "$*" >&2
  exit 1
}

if [ "$#" -lt 1 ]; then
  die "usage: $app_name <file.exe|file.msi|file.bat> [arguments...]"
fi

target=$1
shift

if [ ! -e "$target" ]; then
  die "target does not exist: $target"
fi

validate_proton_path() {
  if [ -d "$proton_path" ]; then
    return 0
  fi

  die "$proton_name not found at $proton_path"
}

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

proc_field_contains() {
  local file=$1
  local needle=$2

  [ -r "$file" ] || return 1
  { tr '\0' '\n' < "$file"; } 2>/dev/null | grep -F -- "$needle" >/dev/null 2>&1
}

detect_umu_nsenter() {
  local proc_dir pid cmdline

  for proc_dir in /proc/[0-9]*; do
    [ -d "$proc_dir" ] || continue
    pid=${proc_dir#/proc/}
    [ "$pid" != "$$" ] || continue

    if ! proc_field_contains "$proc_dir/environ" "WINEPREFIX=$WINEPREFIX" \
      && ! proc_field_contains "$proc_dir/environ" "STEAM_COMPAT_DATA_PATH=$WINEPREFIX" \
      && ! proc_field_contains "$proc_dir/cmdline" "$WINEPREFIX"; then
      continue
    fi

    cmdline=$({ tr '\0' ' ' < "$proc_dir/cmdline"; } 2>/dev/null || true)
    if printf '%s\n' "$cmdline" | grep -E 'pressure-vessel|steam-runtime|umu|pv-bwrap|reaper' >/dev/null 2>&1 \
      || proc_field_contains "$proc_dir/environ" "UMU_ID=$game_id" \
      || proc_field_contains "$proc_dir/environ" "GAMEID=$game_id"; then
      printf '1\n'
      return 0
    fi
  done

  printf '0\n'
}

run_umu_with_gamemode() {
  gamemoderun "$BASH" -c '
    unset LD_PRELOAD
    unset LD_LIBRARY_PATH
    env -u WAYLAND_DISPLAY umu-run "$@"
  ' "$app_name" "$@"
}

validate_proton_path
prefix=${UMU_EXE_UNIVERSAL_WINEPREFIX:-$prefix_default}
mkdir -p "$prefix"

export GAMEID=$game_id
export STORE=none
WINEPREFIX=$(realpath -m "$prefix")
export WINEPREFIX
export PROTONPATH=$proton_path
export PROTON_VERB=run
export UMU_USE_STEAM=1
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

refresh_rate=$(detect_refresh_rate)
fps_limit=$(fps_limit_for_refresh_rate "$refresh_rate")
export MANGOHUD=1
export MANGOHUD_CONFIG="no_display,fps_limit=$fps_limit,vsync=2"

UMU_CONTAINER_NSENTER=$(detect_umu_nsenter)
export UMU_CONTAINER_NSENTER
run_umu_with_gamemode reg.exe add 'HKCU\Software\Wine\X11 Driver' /v Decorated /d N /f

UMU_CONTAINER_NSENTER=$(detect_umu_nsenter)
export UMU_CONTAINER_NSENTER
run_umu_with_gamemode "$target" "$@"
