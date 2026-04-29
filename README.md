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

## nixos-anywhere

The `srv-cloud-2` host declares its disk layout using [nix-community/disko][disko]. [nix-community/nixos-anywhere][nixos-anywhere] will repartition and format the target disks declared in `hosts/srv-cloud-2/disko.nix`.

> [!WARNING]
> This is destructive. The disks declared in `hosts/srv-cloud-2/disko.nix` will be repartitioned and formatted.

Before installation, verify that the target host is reachable, the target user can run passwordless sudo, and the target disks match the devices described in the disko configuration file.

```bash
ssh -i <private-key-path> <user>@<server-ip> \
  'sudo -n true && lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS && free -h'
```

Then, run the following command from a local machine to install NixOS on the server via SSH:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#srv-cloud-2 \
  --target-host <user>@<server-ip> \
  -i <private-key-path> \
  --build-on local \
  --copy-host-keys \
  --generate-hardware-config nixos-generate-config ./hosts/srv-cloud-2/hardware-configuration.nix \
  --print-build-logs
```

> [!WARNING]
> If the target host has less than 1.5 GiB of RAM, the installation may fail during the `kexec` phase. Create and enable a swap file on the target host to reduce the risk of OOM during `kexec`, and pass `--no-disko-deps` to skip installing disko dependencies.

```bash
# target host
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

```bash
# local machine
nix run github:nix-community/nixos-anywhere -- \
  --flake .#srv-cloud-2 \
  --target-host <user>@<server-ip> \
  -i <private-key-path> \
  --build-on local \
  --copy-host-keys \
  --generate-hardware-config nixos-generate-config ./hosts/srv-cloud-2/hardware-configuration.nix \
  --no-disko-deps \
  --print-build-logs
```


[disko]: https://github.com/nix-community/disko
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
