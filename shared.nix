{ lib, pkgs, ... }:
let
  nix-alien-pkgs = import (
    pkgs.fetchFromGitHub {
      owner = "thiagokokada";
      repo = "nix-alien";
      rev = "d6f007b3cab6cd16e50a0041c542a18793357737";
      sha256 = "16djxx5fs35arwbsz74z5bdnikc60wzvqiyc50gzgnnz16drvw5q";
    }
  ) {};
  secrets = import ./secrets.nix;
in
{
  imports = [
    <nixos-wsl/modules>
    <home-manager/nixos>
  ];

  wsl = {
    enable = true;
    defaultUser = "drew";
  };

  system.activationScripts.binbash = {
    deps = [ "binsh" ];
    text = ''
       ln -sfn /bin/sh /bin/bash
    '';
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; with nix-alien-pkgs; [
    nix-alien
  ];

  users.users.drew = {
    shell = pkgs.zsh;
    extraGroups = [ "docker" ];
  };

  home-manager.users.drew = { pkgs, ... }: {
    home.packages = with pkgs; [
      asdf-vm
      fd
      gcc
      gnumake
      unzip
      update-nix-fetchgit
      wget

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
      userName  = secrets.userName;
      userEmail = secrets.userEmail;
      aliases = {
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
      delta = {
        enable = true;
        options = {
          side-by-side = true;
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
        GS4JS_HOME = "${pkgs.ghostscript}/lib";
      };
      shellAliases = {
        n = "nvim";
        tm = "tmux attach || tmux new";
        cat = "bat";
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

    programs.ripgrep.enable = true;
    programs.lazygit.enable = true;
    programs.bat.enable = true;

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
        rev = "13cce81d998630e46b1ad2d60dd10f3013726bb6"; # refs/heads/v2.0
        sha256 = "1ndazbcqqr38zf4mdfc4yqp3rqkkvr03n58wn3655lxp4g9lggfj";
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
