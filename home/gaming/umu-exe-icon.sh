set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'usage: umu-exe-icon <file.exe>\n' >&2
  exit 2
fi

exe=$1

if [ ! -r "$exe" ]; then
  printf '\n'
  exit 0
fi

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/umu-exe-icons"
mkdir -p "$cache_root"

real_exe=$(realpath -m -- "$exe" 2>/dev/null || printf '%s\n' "$exe")
size=$(stat -c '%s' -- "$exe" 2>/dev/null || printf '0')
mtime=$(stat -c '%Y' -- "$exe" 2>/dev/null || printf '0')
cache_version=1
key=$(printf '%s\n%s\n%s\n%s\n' "$cache_version" "$real_exe" "$size" "$mtime" | sha256sum)
key=${key%% *}

icon_png="$cache_root/$key.png"
missing_marker="$cache_root/$key.missing"
lock_dir="$cache_root/$key.lock"
locked=0
work_dir=""

cleanup() {
  if [ -n "$work_dir" ] && [ -d "$work_dir" ]; then
    rm -rf "$work_dir"
  fi

  if [ "$locked" = 1 ]; then
    rmdir "$lock_dir" 2>/dev/null || true
  fi
}

finish_missing() {
  : > "$missing_marker" 2>/dev/null || true
  printf '\n'
  exit 0
}

acquire_lock() {
  local deadline now lock_mtime

  now=$(date +%s)
  deadline=$((now + 15))

  while ! mkdir "$lock_dir" 2>/dev/null; do
    if [ -s "$icon_png" ]; then
      return 1
    fi

    if [ -e "$missing_marker" ]; then
      return 1
    fi

    now=$(date +%s)
    if lock_mtime=$(stat -c '%Y' -- "$lock_dir" 2>/dev/null); then
      if [ $((now - lock_mtime)) -gt 300 ]; then
        rmdir "$lock_dir" 2>/dev/null || true
        continue
      fi
    fi

    if [ "$now" -ge "$deadline" ]; then
      return 1
    fi

    sleep 0.1
  done

  locked=1
  return 0
}

choose_best_png() {
  local candidate file dimensions width rest height depth score
  local best_png="" best_score=-1

  while IFS= read -r candidate; do
    file=${candidate##*/}
    dimensions=${file%.png}
    dimensions=${dimensions##*_}

    case "$dimensions" in
      *x*x*) ;;
      *) continue ;;
    esac

    width=${dimensions%%x*}
    rest=${dimensions#*x}
    height=${rest%%x*}
    depth=${rest#*x}

    case "$width$height$depth" in
      '' | *[!0-9]*) continue ;;
    esac

    score=$((width * height * 1000 + depth))
    if [ "$width" -ne "$height" ]; then
      score=$((width * height))
    fi

    if [ "$score" -gt "$best_score" ]; then
      best_score=$score
      best_png=$candidate
    fi
  done < <(find "$work_dir" -maxdepth 1 -type f -name '*.png' -print)

  if [ -n "$best_png" ]; then
    printf '%s\n' "$best_png"
  fi

  return 0
}

trap cleanup EXIT

if [ -s "$icon_png" ]; then
  printf '%s\n' "$icon_png"
  exit 0
fi

if [ -e "$missing_marker" ]; then
  printf '\n'
  exit 0
fi

if ! acquire_lock; then
  if [ -s "$icon_png" ]; then
    printf '%s\n' "$icon_png"
  else
    printf '\n'
  fi
  exit 0
fi

if [ -s "$icon_png" ]; then
  printf '%s\n' "$icon_png"
  exit 0
fi

if [ -e "$missing_marker" ]; then
  printf '\n'
  exit 0
fi

work_dir=$(mktemp -d "$cache_root/$key.work.XXXXXX")

if ! wrestool -x --type=14 -o "$work_dir" "$exe" >/dev/null 2>&1; then
  finish_missing
fi

found_ico=0
for ico in "$work_dir"/*.ico; do
  [ -e "$ico" ] || continue
  found_ico=1
  icotool -x -o "$work_dir" "$ico" >/dev/null 2>&1 || true
done

if [ "$found_ico" = 0 ]; then
  finish_missing
fi

best_png=$(choose_best_png)
if [ -z "$best_png" ]; then
  finish_missing
fi

tmp_icon="$cache_root/$key.png.$$"
install -m 0644 "$best_png" "$tmp_icon"
mv -f "$tmp_icon" "$icon_png"

printf '%s\n' "$icon_png"
