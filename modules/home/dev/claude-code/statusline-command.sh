#!/usr/bin/env bash
# Status line modeled on Codex tui.status_line items.
input=$(cat)
j() { echo "$input" | jq -r "$1 // empty"; }

model=$(j '.model.display_name')
effort=$(j '.effort.level')
dir=$(j '.workspace.project_dir // .workspace.current_dir // .cwd')
five=$(j '.rate_limits.five_hour.used_percentage')
week=$(j '.rate_limits.seven_day.used_percentage')
size=$(j '.context_window.context_window_size')
remain=$(j '.context_window.remaining_percentage')
used_in=$(j '.context_window.total_input_tokens')
out_tok=$(j '.context_window.total_output_tokens')
cost=$(j '.cost.total_cost_usd')
ver=$(j '.version')

human() { awk -v n="$1" 'BEGIN{ if(n>=1000000) printf "%.1fM",n/1e6; else if(n>=1000) printf "%.1fK",n/1e3; else printf "%d",n }'; }

# True when version $1 is strictly newer than version $2.
is_newer() {
  if [ "$1" = "$2" ]; then
    return 1
  fi
  local highest
  highest=$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)
  [ "$highest" = "$1" ]
}

# Refresh the npm dist-tags in the background at most once per TTL.
# The stamp records each attempt, so an offline machine does not retry
# on every status line render.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
tags_file="$cache_dir/dist-tags.json"
stamp_file="$cache_dir/dist-tags.stamp"
tags_ttl=3600
tags_url="https://registry.npmjs.org/-/package/@anthropic-ai/claude-code/dist-tags"

now=$(date +%s)
stamp_mtime=$(stat -c %Y "$stamp_file" 2>/dev/null || echo 0)
if [ $((now - stamp_mtime)) -ge "$tags_ttl" ]; then
  mkdir -p "$cache_dir"
  touch "$stamp_file"
  # Detach all standard streams so the status line does not wait for curl.
  (
    flock -n 9 || exit 0
    tmp=$(mktemp "$tags_file.XXXXXX") || exit 0
    if curl -fsS --max-time 10 -o "$tmp" "$tags_url" && jq -e '.latest' "$tmp" >/dev/null; then
      mv "$tmp" "$tags_file"
    else
      rm -f "$tmp"
    fi
  ) 9>"$cache_dir/dist-tags.lock" </dev/null >/dev/null 2>&1 &
fi

latest=$(jq -r '.latest // empty' "$tags_file" 2>/dev/null)

# The pnpm shim names the installed package, which can be newer than the
# running session after `pnpm up -g`.
shim="${PNPM_HOME:-$HOME/.local/share/pnpm}/bin/claude"
shim_target=$(sed -n 's/^# cmd-shim-target=//p' "$shim" 2>/dev/null)
installed=""
if [ -n "$shim_target" ]; then
  installed=$(jq -r '.version // empty' "${shim_target%/bin/*}/package.json" 2>/dev/null)
fi

sep=$(printf ' \033[2m·\033[0m ')
parts=()
m="$model"; [ -n "$effort" ] && m="$m $effort"
[ -n "$m" ] && parts+=("$(printf '\033[36m%s\033[0m' "$m")")
[ -n "$dir" ] && parts+=("$(printf '\033[34m%s\033[0m' "$(basename "$dir")")")
[ -n "$five" ] && parts+=("$(printf '\033[35m5h %.0f%%\033[0m' "$five")")
[ -n "$week" ] && parts+=("$(printf '\033[35m7d %.0f%%\033[0m' "$week")")
[ -n "$size" ] && parts+=("$(printf '\033[33mctx %s\033[0m' "$(human "$size")")")
[ -n "$remain" ] && parts+=("$(printf '\033[33m%.0f%% left\033[0m' "$remain")")
[ -n "$used_in" ] && parts+=("$(printf '\033[32min %s\033[0m' "$(human "$used_in")")")
[ -n "$out_tok" ] && parts+=("$(printf '\033[32mout %s\033[0m' "$(human "$out_tok")")")
[ -n "$cost" ] && parts+=("$(printf '\033[32m$%.2f\033[0m' "$cost")")
if [ -n "$ver" ]; then
  ver_part=$(printf '\033[2mv%s\033[0m' "$ver")
  # Keep the space after each icon. In Ghostty, ⟳ fits only inside two
  # cells, and ↑ is centered across two cells only when the next cell is blank.
  if [ -n "$installed" ] && is_newer "$installed" "$ver"; then
    ver_part="$ver_part $(printf '\033[32m⟳ %s\033[0m' "$installed")"
  elif [ -n "$latest" ] && is_newer "$latest" "$ver"; then
    ver_part="$ver_part $(printf '\033[33m↑ %s\033[0m' "$latest")"
  fi
  parts+=("$ver_part")
fi

out=""
for p in "${parts[@]}"; do
  [ -z "$out" ] && out="$p" || out="$out$sep$p"
done
printf '%s\n' "$out"
