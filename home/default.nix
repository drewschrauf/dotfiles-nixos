{
  pkgs,
  secrets,
  ...
}: {
  home.packages = with pkgs; [
    entr
    fd
    gcc
    gdu
    gnumake
    killall
    unzip
    wget

    # nvim utilities
    nodejs
    lua-language-server
    stylua
    nodePackages.typescript-language-server
    terraform-ls
    nodePackages.bash-language-server
    shfmt
    shellcheck
    nil
    alejandra
    eslint_d
    prettierd
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
      PATH = "/home/drew/.dotfiles/bin:$PATH";
    };
    shellAliases = {
      n = "nvim";
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
  };

  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };

  home.stateVersion = "23.05";
}
