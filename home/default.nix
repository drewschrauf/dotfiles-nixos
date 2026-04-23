{
  pkgs,
  secrets,
  ...
}: let
  diffity = pkgs.fetchFromGitHub {
    owner = "kamranahmedse";
    repo = "diffity";
    rev = "a495def6b7058c690b9f047018e442cd0b9b2a71";
    hash = "sha256-bQ/T3CyaEzjGzqjJCoeYqkrtU460SCOWIpsuYJ2zvNM=";
  };
in {
  home.packages = with pkgs; [
    google-chrome
    gh
    entr
    fd
    gcc
    gdu
    gnumake
    killall
    opencode
    unzip
    wget

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

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = secrets.name or "";
        email = secrets.email or "";
      };
      ui = {
        default-command = "status";
      };
    };
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
    };
    enableGitIntegration = true;
    enableJujutsuIntegration = true;
  };

  programs.zsh = {
    enable = true;
    localVariables = {
      FZF_DEFAULT_COMMAND = "rg --files --hidden --glob '!.git' --glob '!.yarn/cache'";
      PATH = "/home/drew/.dotfiles/bin:$PATH";
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
    skills =
      builtins.mapAttrs (name: _: "${diffity}/packages/skills/${name}")
      (builtins.readDir "${diffity}/packages/skills");
    mcpServers = {
      buildkite = {
        type = "http";
        url = "https://mcp.buildkite.com/mcp";
      };
      figma = {
        type = "http";
        url = "https://mcp.figma.com/mcp";
      };
      playwright = {
        command = "npx";
        args = [
          "@playwright/mcp@latest"
          "--ignore-https-errors"
          "--browser"
          "chrome"
          "--executable-path"
          "${pkgs.google-chrome}/bin/google-chrome-stable"
        ];
      };
    };
    settings = {
      permissions = {
        defaultMode = "plan";
        allow = [
          # Tools
          "Web Search"

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

          # Github operations
          "Bash(gh pr view)"
          "Bash(gh pr list)"
          "Bash(gh pr diff)"
        ];
      };
    };
  };

  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };

  home.stateVersion = "23.05";
}
