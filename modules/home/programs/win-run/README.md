# win-run

`win-run` runs Windows EXE and MSI files on Linux and adds installed applications to your Linux application menu. It uses UMU, a launcher for running programs through Proton, with DW-Proton as the default runtime.

Programs share a Wine prefix by default: a directory containing their Windows environment, installed files, and settings. You can select another prefix for a separate environment. Menu registration depends on DW-Proton's generated shortcuts; running an arbitrary EXE does not automatically create a menu entry.

## Install and activate

This utility is packaged as a Home Manager module in this repository. Add the following import to your Home Manager configuration. This example assumes the repository's `flake` module argument is available; `flake.self` refers to this repository's flake outputs:

```nix
{ flake, ... }:

let
  inherit (flake) self;
in
{
  imports = [ self.homeModules.programs-win-run ];
}
```

An external Home Manager configuration must also supply that `flake` argument and a package set providing `dwproton-bin` and `umu-launcher`.

Apply your configuration from the repository root. Choose the command for your configuration; these examples use this repository's notebook profiles:

```bash
# Standalone Home Manager:
home-manager switch --flake .#archlinux@notebook

# NixOS with Home Manager:
sudo nixos-rebuild switch --flake .#notebook
```

Activation installs `win-run`, UMU, an EXE/MSI file handler, and a tray icon proxy. The launcher uses the packaged DW-Proton runtime. The module also registers DW-Proton as a Steam compatibility tool when NixOS Steam does not manage that registration.

To open EXE/MSI files through `win-run` from your file manager, select **Win Run (DW-Proton)** as their default application. This file handler is hidden from application menus; default file associations are left to you.

## First use

Run a Windows installer:

```bash
win-run open /path/to/setup.exe
# Or, for an MSI installer:
win-run open /path/to/setup.msi
```

The prefix directory is created automatically when you run a program. Complete the installer normally. If DW-Proton generates a supported shortcut, an entry named `win-run: <original name>` appears in your Linux application menu. Select that entry to run the installed application again; it retains the prefix used during installation.

For a portable application, run its EXE directly:

```bash
win-run open /path/to/application.exe
```

Portable EXEs are not automatically added to the menu. See [Menu registration](#menu-registration) for discovery conditions.

## Commands

```text
win-run open <file.exe|file.msi> [-- <arguments>...]
win-run launch <entry-id> [--prefix <absolute-path>]
win-run watch
win-run --help
```

`open` runs an existing EXE or MSI file. Place arguments intended for the Windows program after `--`:

```bash
win-run open /path/to/setup.msi -- /quiet
win-run open "/path/to/My Application.exe" -- argument1 "argument with spaces"
```

`launch` runs an application's discovered Windows shortcut. Generated menu entries use this command; normally you can simply select the application in your menu. For manual use, find its `wr1-` identifier and prefix in the `Exec` line of `$XDG_DATA_HOME/applications/win-run-wr1-*.desktop` (by default, `$HOME/.local/share/applications`):

```bash
win-run launch wr1-0123456789abcdef01234567 --prefix /absolute/path/to/prefix
```

Replace the example identifier with the one from your entry. Without `--prefix`, `launch` uses the prefix selected by the environment or the default prefix. Generated menu entries include `--prefix`, so they work without inheriting a custom `WIN_RUN_WORKSPACE`. `launch` does not accept additional Windows program arguments.

`watch` keeps menu synchronization active until you stop it, for example with Ctrl+C. See [Optional session watcher](#optional-session-watcher) for when to use it.

## Prefix and environment

All programs use `$XDG_DATA_HOME/win-run/prefixes/default` unless you select another prefix. When `XDG_DATA_HOME` is unset or empty, the default prefix is `$HOME/.local/share/win-run/prefixes/default`.

| Variable | Purpose |
| --- | --- |
| `WIN_RUN_WORKSPACE` | Select a different Wine prefix directory. |
| `XDG_DATA_HOME` | Data directory for generated Linux menu entries and, by default, the prefix. Falls back to `$HOME/.local/share`. |
| `XDG_RUNTIME_DIR` | Required absolute session runtime directory for watcher coordination. Normally supplied by your Linux session. |
| `WIN_RUN_PROTON` | Override the packaged DW-Proton runtime with a Proton runtime directory. |
| `WIN_RUN_UMU` | Override the packaged UMU launcher with an executable file path. |

For a separate environment, set the prefix before running its installer or application:

```bash
export WIN_RUN_WORKSPACE="$HOME/.local/share/win-run/prefixes/custom"
win-run open /path/to/setup.exe
```

Use the same prefix and data-home settings when starting a separate watcher for that environment. Configuration activation does not modify existing prefixes. `win-run` does not automatically discover, move, or import environments created by other launchers.

## Menu registration

`win-run` discovers applications from `<prefix>/drive_c/proton_shortcuts/*.desktop`, generated by DW-Proton. A candidate must refer to an existing regular Windows `.lnk` shortcut. Missing shortcuts, hidden entries, and uninstall entries are excluded. Start Menu links are not scanned independently, and portable executables are not discovery candidates.

Generated Linux entries are stored in `$XDG_DATA_HOME/applications` and displayed as `win-run: <original name>`. They preserve localized names, comments, icons, and window-class metadata where available. Standard Linux application menus can discover them. Synchronization updates or removes only entries owned by `win-run` for the selected prefix.

Changing `WIN_RUN_PROTON` does not change the discovery format: automatic menu registration still requires the DW-Proton shortcut files described above.

During `open` or `launch`, a shared watcher automatically updates entries as shortcuts and icons change. It performs a final synchronization and stops after the last launcher or explicit `watch` client disconnects. Multiple programs can run concurrently.

If an installed application does not appear in your menu, check that the selected prefix contains a candidate `.desktop` file and the `.lnk` file it references. If shortcuts changed while no watcher was active, run `win-run watch` with that prefix and data-home setting to synchronize them.

## Optional session watcher

No watcher service is installed by default. The automatic watcher handles changes during `open` and `launch`. Run `win-run watch` separately if you also want menu updates while no program is running through the launcher, such as when another tool modifies the prefix.

To keep watching throughout your user session, create `~/.config/systemd/user/win-run-watch.service`:

```ini
[Unit]
Description=Watch win-run application shortcuts

[Service]
Type=simple
ExecStart=%h/.nix-profile/bin/win-run watch
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
```

Replace the executable path with the installed path reported by `command -v win-run` if it differs. For a custom prefix, add `Environment=WIN_RUN_WORKSPACE=/absolute/path/to/custom-prefix` under `[Service]`. For a custom data home, also add `Environment=XDG_DATA_HOME=/absolute/path/to/data-home`. The service must use the same settings as your launches and have an absolute `XDG_RUNTIME_DIR` in its environment.

Enable the service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now win-run-watch.service
```

To stop continuous watching and disable the service:

```bash
systemctl --user disable --now win-run-watch.service
```

## Development and tests

The Go source and `go.mod` live beside this README. The implementation uses the standard library and declares Go 1.24. `manager` implements the CLI, `runtime` launches and supervises UMU, and `applications` discovers shortcuts, writes menu entries, and manages watchers.

Run the packaged test check from the repository root:

```bash
nix build .#checks.x86_64-linux.win-run
```

The check runs `go test ./...` with isolated fixtures. You can also run that Go command directly from `modules/home/programs/win-run` with a compatible Go toolchain.
