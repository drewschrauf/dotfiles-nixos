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
  tmux-claude-overseer/  Bundled tmux plugin (built via tmuxPlugins.mkTmuxPlugin
                         in default.nix) that surfaces which Claude Code
                         sessions need attention. See "Claude session overseer".

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

## Claude session overseer

`home/tmux-claude-overseer/` is a small, self-contained tmux plugin for keeping
an eye on many concurrent Claude Code sessions across tmux panes. It is built in
`home/default.nix` with `pkgs.tmuxPlugins.mkTmuxPlugin` and added to
`programs.tmux.plugins`, so the scripts live in the nix store (not on `$PATH`).

Pieces:

- `scripts/state <working|needs_input|clear>` — stamps the current pane's
  `@claude_state` user option (keyed off `$TMUX_PANE`; no-ops outside tmux).
- `scripts/status` — a catppuccin-mocha status-right bubble showing a count of
  panes waiting on input; silent when none. Placed in `status-right` from
  `default.nix` (the plugin only owns behaviour, not bar placement).
- `scripts/menu` — an `fzf` `display-popup` picker (bound to `M-i` by the
  plugin's `.tmux`) listing Claude panes with a live `capture-pane` preview;
  Enter jumps to the chosen pane.

State is driven by Claude Code **hooks** declared in
`programs.claude-code.settings.hooks` (`UserPromptSubmit`/`PostToolUse` →
`working`, `Stop`/`Notification` → `needs_input`, `SessionEnd` → `clear`), each
invoking `scripts/state` by its nix-store path.

Editing any of these scripts requires a rebuild (`update`) — the live tmux/hooks
reference the store path, so changes are not picked up until the plugin is
rebuilt and `tmux source-file ~/.config/tmux/tmux.conf` is run. Colours are
hardcoded to the mocha palette to match `@catppuccin_flavour`.

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
- `claude-code` itself is configured declaratively in `home/default.nix` — plan-mode default, read-only Bash allowlist, MCP servers, `diffity` skills wired from a pinned GitHub fetch, and the session-overseer hooks (see "Claude session overseer"). Prefer changing Claude Code's global config there rather than editing `~/.claude/settings.json` directly.

## References

- `~/Sync/Documents/Ubuntu/` — standalone setup notes for the apt/system side (e.g. `clamav.md`). Check there before re-deriving host config.
