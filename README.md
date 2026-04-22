# NixOS/HomeManager Configuration Flake

A personal flake for building NixOS systems and standalone Home Manager profiles from a single host inventory.

## Structure

- `flake.nix`: defines `nixosConfigurations`, `homeConfigurations`, `checks`, and `devShells`.
- `hosts.nix`: inventory for all system hosts and Home Manager profiles.
- `hosts/<name>/`: host-specific NixOS modules, hardware config, and optional Home Manager overrides.
- `users/<name>/`: per-user system and home settings.
- `modules/`: reusable NixOS system modules and feature flags.
- `home/`: reusable Home Manager modules shared by both NixOS and non-NixOS targets.
- `overlays/`: overlays for some packages.
- `lib/mkHost.nix`: `mkHost` creates NixOS hosts and integrates Home Manager for the selected user.
- `lib/mkHome.nix`: `mkHome` creates standalone Home Manager profiles from the same inventory.

> [!NOTE]
> `<name>` in `hosts/<name>/` refers to a host key in `hosts.nix`, while `<name>` in `users/<name>/` refers to the username.

> [!WARNING]
> This flake does not currently support multi-user host configurations. Only one user is supported per host/profile.

## Getting Started

### 1. Add a user

Create `users/<name>/home.nix`. `home.nix` is always included in that user's Home Manager setup.

Create `users/<name>/system.nix` if the new user is used in NixOS host configuration.

`users/wtchrs` is my own user configuration. Use this as a starting point.
Replace any user-specific values such as Git identity, signing keys, and email addresses.

### 2. Add a host to `hosts.nix`

`hosts.nix` is the inventory for this flake.

- `system.<name>` creates `nixosConfigurations.<name>`.
- `home.<name>` creates a standalone `homeConfigurations` entry.

Minimal examples:

```nix
{
  system.my-desktop = {
    system = "x86_64-linux";
    user = "alice";
    hostName = "my-desktop";

    my.features = {
      desktop.enable = true;
      nvidia.enable = false;
      gaming.enable = false;
    };
  };

  home.workstation = {
    system = "x86_64-linux";
    user = "alice";
    hostName = "ubuntu-work";
    homeDirectory = "/home/alice";
    stateVersion = "26.05";
  };
}
```

Notes:

- For `system` hosts, `hostName` defaults to the attribute name if omitted.
- For `home` profiles, the output name defaults to `user@hostName` or `user@<attrName>`.
- `profileName` can override the standalone Home Manager output name.
- Feature flags currently used by the repo are `desktop`, `nvidia`, and `gaming`.

### 3. Add host files

For a NixOS host, create `hosts/<name>/default.nix` and add `hardware-configuration.nix`.

- `hosts/<name>/default.nix` is the main host module.
- `hosts/<name>/hardware-configuration.nix` should come from the target machine.
- `hosts/<name>/system/*.nix` is auto-imported for extra system-only host settings.
- `hosts/<name>/home/*.nix` is auto-imported into that host's Home Manager config.

For a Home Manager-only target, only the `home.<name>` entry in `hosts.nix` is required unless you also want `hosts/<name>/home/*.nix` overrides.

### 4. Apply on NixOS

Install NixOS normally first, then move this repo onto the machine and add the host entry/files above.

Apply the system with:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

Example:

```bash
sudo nixos-rebuild switch --flake .#notebook
```

### 5. Apply with Home Manager

On non-NixOS Linux, install Nix and Home Manager first, then apply the matching profile:

```bash
home-manager switch --flake .#<profile>
```

Example:

```bash
home-manager switch --flake .#wtchrs@archlinux
```
