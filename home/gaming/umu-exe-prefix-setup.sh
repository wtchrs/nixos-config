set -euo pipefail

app_name="umu-exe-prefix-setup"

# shellcheck source=/dev/null
. "@umuExeCommon@"

init_umu_exe_prefix_env

UMU_CONTAINER_NSENTER=$(detect_umu_nsenter)
export UMU_CONTAINER_NSENTER

run_umu_with_gamemode reg.exe add 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d 120 /f
run_umu_with_gamemode reg.exe add 'HKCU\Software\Wine\X11 Driver' /v Decorated /d N /f

printf '%s: configured Wine registry for %s\n' "$app_name" "$WINEPREFIX"
