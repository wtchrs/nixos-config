set -euo pipefail

mode="${1:-area}"
screenshot_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$screenshot_dir"
screenshot_path="$screenshot_dir/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"

case "$mode" in
  area)
    geometry="$(slurp)" || exit 0
    grim -g "$geometry" "$screenshot_path"
    ;;
  screen)
    grim "$screenshot_path"
    ;;
  *)
    echo "usage: labwc-screenshot [area|screen]" >&2
    exit 2
    ;;
esac
