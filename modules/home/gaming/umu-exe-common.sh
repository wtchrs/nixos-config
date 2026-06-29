proton_name="@protonName@"
proton_path="@protonPath@"
game_id="umu-exe-universal"
prefix_default="$HOME/Games/umu/exe-universal"

die() {
  printf '%s: %s\n' "$app_name" "$*" >&2
  exit 1
}

validate_proton_path() {
  if [ -d "$proton_path" ]; then
    return 0
  fi

  die "$proton_name not found at $proton_path"
}

init_umu_exe_prefix_env() {
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
