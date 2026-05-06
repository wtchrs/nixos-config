set -euo pipefail

prefix="${UMU_EXE_UNIVERSAL_WINEPREFIX:-$HOME/Games/umu/exe-universal}"
drive_c="$prefix/drive_c"

if [ ! -d "$drive_c" ]; then
  printf '[]\n'
  exit 0
fi

emit_item() {
  local name=$1
  local exe=$2
  local description=$3

  jq -cn \
    --arg name "$name" \
    --arg exec "umu-exe-universal \"$exe\"" \
    --arg description "$description" \
    '{name:$name, exec:$exec, icon:"", description:$description}'
}

pretty_name() {
  local path=$1
  local base parent

  base=${path##*/}
  base=${base%.exe}
  parent=${path%/*}
  parent=${parent##*/}

  case "$base" in
    [Uu]ninstall* | unins[0-9]* | crashpad_handler | update | updater | maintenancetool)
      printf '%s\n' "$parent"
      ;;
    *)
      printf '%s\n' "$base"
      ;;
  esac
}

is_interesting_exe() {
  local path=$1
  local base lower

  base=${path##*/}
  lower=$(printf '%s\n' "$base" | tr '[:upper:]' '[:lower:]')

  case "$lower" in
    uninstall*.exe | unins*.exe | update.exe | updater.exe | crashpad_handler.exe | \
    crashreporter.exe | diagreport.exe | maintenancetool.exe | iexplore.exe | wmplayer.exe | wordpad.exe)
      return 1
      ;;
  esac

  case "$path" in
    */drive_c/Program\ Files/Internet\ Explorer/* | \
    */drive_c/Program\ Files/Windows\ Media\ Player/* | \
    */drive_c/Program\ Files/Windows\ NT/* | \
    */drive_c/Program\ Files\ \(x86\)/Internet\ Explorer/* | \
    */drive_c/Program\ Files\ \(x86\)/Windows\ Media\ Player/* | \
    */drive_c/Program\ Files\ \(x86\)/Windows\ NT/*)
      return 1
      ;;
  esac

  case "$path" in
    */drive_c/Program\ Files/* | \
    */drive_c/Program\ Files\ \(x86\)/* | \
    */drive_c/users/*/AppData/Local/Programs/*)
      return 0
      ;;
  esac

  return 1
}

description_for() {
  local exe=$1
  local path=${exe#"$drive_c/"}

  printf 'Windows app in %s' "$path"
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

find "$drive_c" -type f -iname '*.exe' -print 2>/dev/null |
  while IFS= read -r exe; do
    is_interesting_exe "$exe" || continue
    name=$(pretty_name "$exe")
    desc=$(description_for "$exe")
    emit_item "$name" "$exe" "$desc"
  done > "$tmp"

if [ ! -s "$tmp" ]; then
  printf '[]\n'
  exit 0
fi

sort -u "$tmp" |
  jq -s -c '
    unique_by(.exec)
    | sort_by(.name | ascii_downcase)
    | map(.name = ("UMU: " + .name))
  '
