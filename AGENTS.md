# Project Instructions

## Scope

Apply these rules throughout this repository.
Use `README.md` for the repository layout and profile names.
Keep all project-specific agent instructions in the repository root `AGENTS.md`.
Do not create or use directory-specific `AGENTS.md` files.

## Local Flake Commands

Use explicit `path:` references to include untracked files in local flake commands without `git add`.
A Git-based flake reference omits untracked files.

- Run local flake commands from the repository root.
- Use `path:.#...` when a command selects a flake output.
- Use `path:.` when a command selects the flake without an output.
- Apply this rule to checks, builds, and evaluations.
- Do not change the Git index to make Nix include untracked files.
- Do not use `git add` or `git add -N` for this purpose.

For example, check the flake without a build:

```bash
nix flake check path:. --no-build --no-write-lock-file
```

For example, evaluate the notebook system derivation:

```bash
nix eval --raw 'path:.#nixosConfigurations.notebook.config.system.build.toplevel.drvPath'
```

## Configuration Activation

Do not run commands that activate NixOS or Home Manager configurations.
Do not run commands that change the system boot configuration.

This restriction includes:

- `nixos-rebuild switch`, `nixos-rebuild boot`, and `nixos-rebuild test`.
- Direct calls to `switch-to-configuration`.
- `home-manager switch`.
- Direct execution of Home Manager `activate` scripts.

Use `nix eval`, `nix build`, `nix flake check`, or `home-manager build` for validation.

## File Maintenance

- Write instructions in English.
- Follow ASD-STE100 writing principles where practical.
- Use short sentences and the active voice.
- Give one instruction in each sentence.
- Use the same technical term for the same concept.
- Keep necessary technical terms and exact command syntax.
- Put new rules under the applicable topic heading.
- Add a topic heading when no existing heading applies.
- Keep each rule in one place.
- Do not repeat the global working agreements.
