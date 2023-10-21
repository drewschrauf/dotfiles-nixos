{ config, lib, pkgs, ... }:
{
  imports = [
    <nixos-wsl/modules>
    <home-manager/nixos>
  ];

  wsl = {
    enable = true;
    defaultUser = "drew";
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  users.users.drew = {
    shell = pkgs.zsh;
    extraGroups = [ "docker" ];
  };

  home-manager.users.drew = { pkgs, ... }: {
    home.packages = with pkgs; [
      asdf-vm
      bash
      bat
      eza
      lazygit
      ripgrep
      update-nix-fetchgit

      # nvim utilities
      lua-language-server
      stylua
      nodePackages.typescript-language-server
      prettierd
      eslint_d
      terraform-ls
      rust-analyzer
      nodePackages.bash-language-server
      shfmt
      shellcheck
      nil
    ];

    programs.git = {
      enable = true;
      userName  = (import ./secrets.nix).userName;
      userEmail = (import ./secrets.nix).userEmail;
      aliases = {
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
      delta = {
        enable = true;
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
      sessionVariables = {
        NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.stdenv.cc.cc
        ];
        NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
      };
      localVariables = {
        EDITOR = "nvim";
        FZF_DEFAULT_COMMAND = "rg --files --hidden --glob '!.git' --glob '!esy.lock' --glob '!.yarn/cache'";

        PATH = "/home/drew/.dotfiles/bin:$PATH";
      };
      shellAliases = {
        n = "nvim";
        tm = "tmux attach || tmux new";
        ls = "exa";
        cat = "bat";

        ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir";
        tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir";
        tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";
      };
      initExtra = ''
        autoload -Uz promptinit && promptinit && prompt pure
        . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
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

          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-syntax-highlighting kind:defer"

          "sindresorhus/pure kind:fpath"
        ];
      };
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
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

    programs.neovim = {
      enable = true;
    };

    home.file.".config/nvim" = {
      source = pkgs.fetchFromGitHub {
        owner = "NvChad";
        repo = "NvChad";
        rev = "c56f1242dfc9c1fbba71fc3a22448d5d563703e0"; # refs/heads/v2.0
        sha256 = "0vkk8d9v3x7m7612z8r3nrmwxj25vwbv67wc2vjn0yfahmagf0fy";
      };
      recursive = true;
    };

    home.file.".config/nvim/lua/custom" = {
      source = ./nvchad-custom;
      recursive = true;
    };

    home.file.".tool-versions".text = ''
      nodejs 18.14.1
    '';

    home.stateVersion = "23.05";
  };

  system.stateVersion = "23.05";
}
