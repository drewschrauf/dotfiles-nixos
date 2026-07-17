# Dotfiles

A personal Nix flake that drives a [home-manager](https://github.com/nix-community/home-manager) configuration for Drew's CLI environment on a Linux desktop (Ubuntu in practice, but nothing here is Ubuntu-specific). This is **not** a system-config repo.

## Core principle: what belongs in Nix

Nix manages **user-mode CLI tools and dotfiles only** — shells, editors, dev CLIs, formatters, LSPs, terminal utilities.

Anything system-level or GUI is installed outside this repo, via `apt`. Examples that live on the host, not in Nix:

- GUI apps (Zoom, browsers, IDEs, etc.)
- System daemons / services (ClamAV)
- Kernel modules, drivers, fonts wired into the desktop
- Anything that needs `systemd` integration or a `.desktop` entry

Default answer when asked "should we add X to Nix?": if X is a GUI app, daemon, kernel-adjacent, or otherwise needs system integration, the answer is no — install with `apt` and document it under `~/Sync/Documents/Ubuntu/`.

## Layout

```
flake.nix / flake.lock   Flake inputs: nixpkgs (unstable), home-manager,
                         optional secrets, plus a legacy nixos-wsl input.

home/
  default.nix            Base home-manager module: packages, git, zsh +
                         antidote, tmux, fzf/rg/bat/jq/direnv/eza, neovim,
                         claude-code config.
  work.nix               Layered on top of default.nix in the live config;
                         adds work CLIs (awscli2, kubectl, yarn, python3,
                         mongosh, mise, ...) and work-specific zsh aliases.
  personal.nix           Empty stub. Only referenced by the legacy
                         nixosConfigurations.personal output.
  nvim/                  Neovim config, symlinked into ~/.config/nvim via
                         home.file.

nixos/                   Legacy NixOS-WSL2 modules. See "Legacy WSL bits".

bin/
  update                 Apply the live home-manager config.
  upgrade                Bump flake.lock + reapply + refresh plugins.
  shell                  Ad-hoc `nix shell` wrapper.
```

`bin/` is on `$PATH` via the zsh config, so `update` / `upgrade` / `shell` are runnable directly.

## Applying changes

- `update` — runs `nix run home-manager/master -- switch --flake .#drew`. If `~/.secrets/flake.nix` exists, it's wired in via `--override-input secrets`.
- `upgrade` — bumps `flake.lock`, runs `update`, then `antidote update`, then `nvim +Lazy! sync`. Use this for routine refreshes.
- `shell <pkg>` — drops into a one-off `nix shell` from nixpkgs unstable. Use for things not worth adding to the config.

The only flake output actually applied on this machine is `homeConfigurations.drew`, which is `home/default.nix` + `home/work.nix`.

## Legacy WSL bits

This repo was previously used to run NixOS under WSL2. That setup is dormant — Drew runs Nix on top of Ubuntu now, not as the OS. The following exist only to support the old WSL2 path and are cleanup candidates, but don't remove them without an explicit ask:

- `nixos-wsl` input in `flake.nix`
- `nixosConfigurations.personal` and `nixosConfigurations.work` outputs
- `nixos/default.nix`, `nixos/work.nix`
- `home/personal.nix` (empty stub, only referenced by the legacy `personal` config)

## Conventions

- Nix files are formatted with `alejandra` (already in `home.packages`).
- `nixpkgs.config.allowUnfree = true` is set in both flake outputs.
- `home.stateVersion = "23.05"` — don't bump casually.
- Secrets (git name/email, etc.) come from `~/.secrets/flake.nix` via `--override-input secrets`. When absent, secrets fall back to empty defaults via the `input-output-hk/empty-flake` input.
- `claude-code` itself is configured declaratively in `home/default.nix` — plan-mode default, read-only Bash allowlist, MCP servers, `diffity` skills wired from a pinned GitHub fetch, and the herdr `SessionStart` hook. Prefer changing Claude Code's global config there rather than editing `~/.claude/settings.json` directly.

## References

- `~/Sync/Documents/Ubuntu/` — standalone setup notes for the apt/system side (e.g. `clamav.md`). Check there before re-deriving host config.
