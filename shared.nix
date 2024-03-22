{
  lib,
  pkgs,
  ...
}: let
  nix-alien-pkgs = import (
    pkgs.fetchFromGitHub {
      owner = "thiagokokada";
      repo = "nix-alien";
      rev = "75c0c2d5eb1fdd2c5187c49888cab40b060605fa";
      sha256 = "1phkcx9nk215hjl34f38nkn2yk63jk2n8hxn8im67qk8jvrwqif3";
    }
  ) {};
  secrets = import ./secrets.nix;
in {
  imports = [
    <nixos-wsl/modules>
    <home-manager/nixos>
  ];

  wsl = {
    enable = true;
    defaultUser = "drew";
  };

  environment.systemPackages = with pkgs;
  with nix-alien-pkgs; [
    nix-alien
  ];

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  system.activationScripts.binbash = {
    deps = ["binsh"];
    text = ''
      ln -sfn /bin/sh /bin/bash
    '';
  };

  users.users.drew = {
    shell = pkgs.zsh;
    extraGroups = ["docker"];
  };

  home-manager.users.drew = {pkgs, ...}: {
    home.packages = with pkgs; [
      asdf-vm
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
    ];

    programs.git = {
      enable = true;
      userName = secrets.userName;
      userEmail = secrets.userEmail;
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
        NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

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
        . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
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

          "zsh-users/zsh-autosuggestions"
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
      enableAliases = true;
      icons = true;
      git = true;
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    home.file.".config/nvim" = {
      source = pkgs.fetchFromGitHub {
        owner = "NvChad";
        repo = "NvChad";
        rev = "44a24e2fe5337b09b4a9ed44bdd001e672d99ec9"; # refs/heads/v2.0
        sha256 = "0w2blllrkkhm3glbmhcddvw8rqx29wqk82wrr4r9chrrvk6zfqy6";
      };
      recursive = true;
    };

    home.file.".config/nvim/lua/custom" = {
      source = ./nvchad-custom;
      recursive = true;
    };

    home.file.".asdfrc".text = ''
      legacy_version_file = yes
    '';

    home.file.".tool-versions".text = ''
      nodejs 20.9.0
    '';

    home.stateVersion = "23.05";
  };

  system.stateVersion = "23.05";
}
