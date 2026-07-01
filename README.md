# NixOS Configuration

Personal Nix flake for NixOS hosts and standalone Home Manager profiles.

## Outputs

- `nixosConfigurations`: `notebook`, `vm`, `srv-cloud-2`
- `homeConfigurations`: `wtchrs@archlinux`, `ubuntu@srv-cloud-1`
- `nixosModules`: reusable NixOS modules exported from `modules/nixos`
- `homeModules`: reusable Home Manager modules exported from `modules/home`
- `overlays`: package overlays used by this flake

## Layout

- `flake.nix`: delegates flake assembly to `nixos-unified`.
- `modules/flake-parts/`: defines flake outputs, checks, dev shells, modules, and overlays.
- `configurations/nixos/<host>/default.nix`: entry point for each NixOS host.
- `configurations/home/<profile>/default.nix`: entry point for each standalone Home Manager profile.
- `modules/nixos/`: shared NixOS modules.
- `modules/home/`: shared Home Manager modules.
- `overlays/`: local package overlays.
- `lib/gaming-proton.nix`: shared gaming helper exported as `lib.gaming-proton`.

## Usage

Apply a NixOS host:

```bash
sudo nixos-rebuild switch --flake .#notebook
```

Apply a standalone Home Manager profile:

```bash
home-manager switch --flake .#wtchrs@archlinux
```

Run checks:

```bash
nix flake check
```

## Adding Configurations

Add NixOS hosts under `configurations/nixos/<host>/default.nix` and register them in `modules/flake-parts/configurations.nix`.

Add standalone Home Manager profiles under `configurations/home/<profile>/default.nix` and register them in `modules/flake-parts/configurations.nix`.

Configuration entries should import shared modules through `self.nixosModules.*` and `self.homeModules.*`.

## srv-cloud-2 Installation

`srv-cloud-2` uses `disko`; installing with `nixos-anywhere` repartitions the disks declared in `configurations/nixos/srv-cloud-2/disko.nix`. This is destructive.

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#srv-cloud-2 \
  --target-host <user>@<server-ip> \
  -i <private-key-path> \
  --build-on local \
  --copy-host-keys \
  --generate-hardware-config nixos-generate-config ./configurations/nixos/srv-cloud-2/hardware-configuration.nix \
  --print-build-logs
```
