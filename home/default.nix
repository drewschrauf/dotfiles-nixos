{
  pkgs,
  secrets,
  ...
}: {
  home.packages = with pkgs; [
    entr
    fd
    gcc
    gnumake
    killall
    unzip
    update-nix-fetchgit
    wget

    # nvim utilities
    lua-language-server
    stylua
    nodePackages.typescript-language-server
    terraform-ls
    rust-analyzer
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
    userName = secrets.name or "";
    userEmail = secrets.email or "";
    delta = {
      enable = true;
      options = {
        navigate = true;
      };
    };
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
    };
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
    };
    initExtra = ''
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
      catppuccin
      yank
    ];
    terminal = "tmux-256color";
    extraConfig = ''
      set-option -sa terminal-overrides ",xterm*:Tc"
      set-option -g renumber-windows on
      set -g @catppuccin_flavour 'mocha'

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Open splits at the same path
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };

  programs.fzf.enable = true;
  programs.ripgrep.enable = true;
  programs.lazygit.enable = true;
  programs.bat.enable = true;
  programs.jq.enable = true;
  programs.direnv.enable = true;
  programs.btop.enable = true;

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = true;
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
