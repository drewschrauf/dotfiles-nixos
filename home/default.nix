{
  pkgs,
  lib,
  config,
  secrets,
  ...
}: let
  mcpServers = {
    buildkite = {
      type = "http";
      url = "https://mcp.buildkite.com/mcp";
    };
    clickup = {
      type = "http";
      url = "https://mcp.clickup.com/mcp";
    };
    figma = {
      type = "http";
      url = "https://mcp.figma.com/mcp";
    };
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
    };
    chrome-devtools = {
      type = "stdio";
      command = "npx";
      args = ["-y" "chrome-devtools-mcp@latest"];
    };
  };

  # Herdr <-> Claude Code integration. `herdr integration install claude` drops
  # a SessionStart hook script that reports the Claude session identity to
  # herdr's socket (wired into programs.claude-code.settings.hooks below). We
  # can't point the installer at ~/.claude/settings.json — home-manager owns it
  # as a read-only symlink — so herdr generates and owns just the *script* in a
  # writable dir at activation (kept current with the installed herdr on every
  # `update`), and we declare the SessionStart entry ourselves. Drop this in
  # favour of a native module option if one lands upstream.
  herdrClaudeDir = "${config.home.homeDirectory}/.local/share/herdr-claude";
  herdrClaudeHook = "${herdrClaudeDir}/hooks/herdr-agent-state.sh";

  # Herdr Navigator plugin, from its prebuilt release. herdr's own `plugin
  # install` would git-clone + `cargo build`; we skip that by fetching the
  # release tarball and laying the binary out at the path the manifest's action
  # commands expect (`./target/release/herdr-navigator`), then registering the
  # store dir with `herdr plugin link` at activation (herdr won't discover a
  # plugin from config.toml alone). Prebuilt glibc binary — runs natively on
  # Ubuntu, no patchelf. Requires herdr >= 0.7.3. Bump version+hash together to
  # update (grab the tarball sha256 from the GitHub release).
  herdrNavigator = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-navigator";
    version = "0.3.2";
    src = pkgs.fetchurl {
      url = "https://github.com/thanhdat77/herdr-navigator/releases/download/v0.3.2/herdr-navigator-linux-x86_64.tar.gz";
      hash = "sha256-2Da73RdiC19Rg8hjxCieG3cfTq4Rm0dyRPEpxNrcW9M=";
    };
    sourceRoot = "herdr-navigator";
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/target/release
      cp herdr-plugin.toml $out/
      install -m755 herdr-navigator $out/target/release/herdr-navigator
      runHook postInstall
    '';
  };

  # Herdr Reviewr plugin. Unlike navigator, its release tarball ships *only* the
  # binary — the manifest and the `herdr/*.sh` action scripts live in the repo
  # source. So we assemble the plugin dir from two pinned sources: the GitHub
  # source (manifest + scripts) and the prebuilt binary, dropped at the path the
  # manifest/scripts expect (`$HERDR_PLUGIN_ROOT/bin/herdr-reviewr`). herdr runs
  # plugin scripts with a minimal PATH and `herdr` isn't in a system dir on this
  # Nix host, so we prepend the store bins the scripts shell out to (jq/git/herdr
  # + coreutils). Prebuilt glibc binary — no patchelf. Bump version + all three
  # hashes together on update (source hash from `nix-prefetch-url --unpack`; the
  # binary sha256 is in the release's .sha256 sidecar).
  herdrReviewr = let
    version = "0.18.1";
    reviewrBin = pkgs.fetchurl {
      url = "https://github.com/persiyanov/herdr-reviewr/releases/download/v${version}/herdr-reviewr-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-JSuB5OugsJeaa0bvUJCfr4jSdTdI2LY8JPg2kHpCXG4=";
    };
  in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "herdr-reviewr";
      inherit version;
      src = pkgs.fetchFromGitHub {
        owner = "persiyanov";
        repo = "herdr-reviewr";
        rev = "v${version}";
        hash = "sha256-bnUCJyqYLmLjeg4g8Z4r6IDPVQzxaSrmj+F6EBVDuis=";
      };
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp -r herdr-plugin.toml herdr $out/
        tar xzf ${reviewrBin} -C $out/bin
        chmod +x $out/bin/herdr-reviewr $out/herdr/*.sh
        substituteInPlace $out/herdr/sidebar.sh \
          --replace-fail '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin' \
                         '${lib.makeBinPath [pkgs.jq pkgs.git pkgs.herdr pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.gnugrep]}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'
        runHook postInstall
      '';
    };
in {
  home.packages = with pkgs; [
    gh
    entr
    fd
    gcc
    gdu
    gnumake
    killall
    unzip
    wget
    xclip

    # nvim utilities
    nodejs
    lua-language-server
    stylua
    typescript-language-server
    terraform-ls
    bash-language-server
    shfmt
    shellcheck
    nil
    alejandra
    eslint_d
    prettierd
    lsof

    # opencode utilities
    ast-grep
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = secrets.name or "";
        email = secrets.email or "";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
    };
    signing.format = null;
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
    };
    enableGitIntegration = true;
  };

  programs.zsh = {
    enable = true;
    localVariables = {
      FZF_DEFAULT_COMMAND = "rg --files --hidden --glob '!.git' --glob '!.yarn/cache'";
      PATH = "/home/drew/.dotfiles/bin:/home/drew/.local/bin:$PATH";
    };
    shellAliases = {
      n = "nvim";
      c = "claude";
      tm = "tmux attach || tmux new";
      cat = "bat";
      yr = "yarn $(cat package.json | jq -r '.scripts | 'keys'[]' | sort -r | fzf --no-sort) $1";
      gwts = "cd $(git worktree list | sed 's/^\\([^ ]*\\).*\\[\\(.*\\)\\]$/\\2 (\\1)/' | fzf | sed 's/^.*(\\(.*\\))$/\\1/')";
      gwtp = "gwtls | fzf -m | sed 's/^\\([^ ]*\\) .*$/\\1/' | xargs -L 1 -t git worktree remove";
    };
    initContent = ''
      autoload -Uz promptinit && promptinit && prompt pure
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local
    '';

    antidote = {
      enable = true;
      plugins = [
        "ohmyzsh/ohmyzsh path:lib/history.zsh"
        "ohmyzsh/ohmyzsh path:lib/completion.zsh"
        "ohmyzsh/ohmyzsh path:lib/git.zsh"

        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/npm"
        "ohmyzsh/ohmyzsh path:plugins/yarn"
        "ohmyzsh/ohmyzsh path:plugins/wd"
        "ohmyzsh/ohmyzsh path:plugins/aws"
        "ohmyzsh/ohmyzsh path:plugins/kubectl"

        "MichaelAquilina/zsh-you-should-use"

        "zsh-users/zsh-autosuggestions kind:defer"
        "zsh-users/zsh-syntax-highlighting kind:defer"

        "sindresorhus/pure kind:fpath"
      ];
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    mouse = true;
    focusEvents = true;
    keyMode = "vi";
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = catppuccin;
        extraConfig = "set -g @catppuccin_flavour 'mocha'";
      }
      yank
    ];
    terminal = "tmux-256color";
    extraConfig = ''
      set-option -sa terminal-overrides ",xterm*:Tc"
      set-option -g renumber-windows on
      set -g set-clipboard on

      # Mouse-drag-select copies to system clipboard without leaving copy-mode,
      # so scrollback position is preserved.
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-no-clear "xclip -selection clipboard -i"

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Open splits at the same path
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Additional catppuccin setup
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -ag status-right "#{E:@catppuccin_status_session}"
    '';
  };

  programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      keys.prefix = "ctrl+a";

      # Herdr Navigator plugin actions (plugin itself is built + registered via
      # the herdrNavigator derivation + herdrNavigatorPlugin activation step).
      keys.command = [
        {
          key = "prefix+t";
          type = "plugin_action";
          # open (overlay), not open-side (split): a temporary overlay floats
          # over the active pane and restores the exact layout on dismiss, rather
          # than inserting a pane that reflows/squishes the others. With preview
          # off + compact rows it's just a clean agent list that pops and vanishes.
          command = "herdr-navigator.open";
          description = "navigator: agent picker";
        }
        # {
        #   key = "prefix+g";
        #   type = "plugin_action";
        #   command = "herdr-navigator.jump-back";
        #   description = "navigator: jump back";
        # }
        {
          key = "prefix+r";
          type = "plugin_action";
          command = "persiyanov.reviewr.toggle";
          description = "reviewr: toggle diff sidebar";
        }
      ];

      # herdr already ships the Catppuccin theme by default (`herdr
      # --default-config`: theme.name defaults to "catppuccin", auto_switch
      # off). We pin theme.name explicitly here because plugins that inherit the
      # herdr theme (herdr-navigator's `inherit_herdr = true`) read *this file*
      # for a theme name and fall back to a light palette when none is set —
      # relying on herdr's built-in default isn't enough for them.
      theme.name = "catppuccin";

      # The catch: herdr has no own-background option, so it uses the
      # *terminal's* background as its canvas and draws dividers in Catppuccin
      # surface shades on top. Once Ghostty also paints the Catppuccin Mocha base
      # (#1e1e2e), those surface dividers sit on a matching background and vanish.
      # Since the base isn't ours to repaint, nudge Catppuccin's own surface ramp
      # up one rung so the dividers clear the base. All values are real Catppuccin
      # Mocha shades (surface0/1/2 = #313244/#45475a/#585b70); roles confirmed by
      # a diagnostic pass: surface_dim = sidebar<->content divider + selected row,
      # surface0/1 = inter-pane split dividers.
      theme.custom = {
        surface_dim = "#45475a";
        surface0 = "#45475a";
        surface1 = "#585b70";
      };
    };
  };

  # Narrow herdr-navigator into an agents-only, status-ordered picker. This is
  # navigator's OWN config file, separate from herdr's config.toml (herdr's
  # settings never reach it). Managed here so the picker is declarative: only
  # agents (no workspace/project/dir sources — herdr's prefix+w already covers
  # those), sorted by status (priority = blocked/error → attention → done →
  # working → idle), no right-side preview, compact rows. Navigator writes its
  # own state files (update-check, etc.) as siblings; owning just config.toml as
  # a symlink is fine. Theme inherits herdr's pinned catppuccin (see above).
  xdg.configFile."herdr/plugins/config/herdr-navigator/config.toml".source = (pkgs.formats.toml {}).generate "herdr-navigator-config.toml" {
    picker = {
      source_order = ["agent"];
      agent_sort = "priority";
      preview = false;
      detailed_rows = false;
      check_updates = false;
    };
    sources = {
      agents = true;
      open_workspaces = false;
      herdr_plus_projects = false;
      zoxide = false;
      roots = false;
      servers = false;
      sessions = false;
      herdr_plus_quick_actions = false;
    };
    jump_back.enabled = false;
    theme.inherit_herdr = true;
  };

  programs.fzf.enable = true;
  programs.ripgrep.enable = true;
  programs.bat.enable = true;
  programs.jq.enable = true;
  programs.direnv.enable = true;
  programs.btop.enable = true;

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
  };

  programs.claude-code = {
    enable = true;
    context = ''
      ## Plan mode

      When plan mode is active, do not edit, create, or delete any files other
      than the designated plan file, and do not run any non-read-only tools.
      Produce a plan, present it for review, and wait for explicit approval
      before taking any action on the codebase.
    '';
    settings = {
      skipAutoPermissionPrompt = true;
      voice = {
        enabled = true;
        mode = "tap";
      };
      permissions = {
        defaultMode = "plan";
        allow = [
          # Tools
          "Web Search(*)"
          "Fetch(*)"

          # Read-only bash commands
          "Bash(find *)"
          "Bash(grep *)"
          "Bash(rg *)"
          "Bash(ls *)"
          "Bash(cat *)"
          "Bash(head *)"
          "Bash(tail *)"
          "Bash(tree *)"
          "Bash(wc *)"
          "Bash(pwd)"
          "Bash(which *)"
          "Bash(echo *)"

          # Additional bash commands
          "Bash(xargs cat *)"
          "Bash(sed *)"
          "Bash(ast-grep *)"

          # Git read operations
          "Bash(git status *)"
          "Bash(git diff *)"
          "Bash(git log *)"
          "Bash(git show *)"
          "Bash(git branch *)"
          "Bash(git mv *)"

          # Yarn/npm commands for testing/building
          "Bash(yarn *)"
          "Bash(npm run *)"
          "Bash(npm view *)"

          # Github operations
          "Bash(gh pr view)"
          "Bash(gh pr list)"
          "Bash(gh pr diff)"
        ];
      };

      # Report this Claude session's identity to herdr's socket so it can
      # attach/restore the pane. Script is generated by the herdrClaudeIntegration
      # activation step; it no-ops unless running inside herdr.
      hooks = {
        SessionStart = [
          {
            matcher = "*";
            hooks = [
              {
                type = "command";
                command = "bash ${lib.escapeShellArg herdrClaudeHook} session";
                timeout = 10;
              }
            ];
          }
        ];
      };
    };
  };

  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # Let herdr (re)generate its Claude hook script into a writable dir on each
  # activation, so it tracks the installed herdr version. The SessionStart entry
  # that invokes it is declared in programs.claude-code.settings.hooks.
  home.activation.herdrClaudeIntegration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${lib.escapeShellArg herdrClaudeDir}
    CLAUDE_CONFIG_DIR=${lib.escapeShellArg herdrClaudeDir} \
      ${pkgs.herdr}/bin/herdr integration install claude
  '';

  # Register the Navigator plugin with herdr from its Nix store path. Re-linked
  # on every activation so it tracks the current store path; failures are
  # ignored so activation still succeeds if herdr can't link (e.g. < 0.7.3).
  # The store path is retained by this generation, so it won't be GC'd.
  home.activation.herdrNavigatorPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.herdr}/bin/herdr plugin unlink herdr-navigator >/dev/null 2>&1 || true
    ${pkgs.herdr}/bin/herdr plugin link ${herdrNavigator} >/dev/null 2>&1 || true
  '';

  # Same link-at-activation pattern as the navigator plugin above; reviewr's
  # plugin id is persiyanov.reviewr (see its manifest).
  home.activation.herdrReviewrPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.herdr}/bin/herdr plugin unlink persiyanov.reviewr >/dev/null 2>&1 || true
    ${pkgs.herdr}/bin/herdr plugin link ${herdrReviewr} >/dev/null 2>&1 || true
  '';

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_JSON="$HOME/.claude.json"
    NEW_MCP=${lib.escapeShellArg (builtins.toJSON mcpServers)}
    if [ -f "$CLAUDE_JSON" ]; then
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq --argjson mcp "$NEW_MCP" '.mcpServers = $mcp' "$CLAUDE_JSON" > "$tmp"
      mv "$tmp" "$CLAUDE_JSON"
    else
      printf '{"mcpServers":%s}\n' "$NEW_MCP" > "$CLAUDE_JSON"
    fi
  '';

  home.stateVersion = "23.05";

  news.display = "silent";
}
