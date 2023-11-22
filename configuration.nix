{ lib, pkgs, ... }:
let
  nix-alien-pkgs = import (
    pkgs.fetchFromGitHub {
      owner = "thiagokokada";
      repo = "nix-alien";
      rev = "d37ba197c51addb2979a042769c5fd1e2b76412a";
      sha256 = "16r80gpprj1viwzmam4ikzl0q2rn458wf3ky66v9zyajax7zhw08";
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
    nginx
  ];

  users.users.drew = {
    shell = pkgs.zsh;
    extraGroups = [ "docker" ];
  };

  home-manager.users.drew = { pkgs, ... }: {
    home.packages = with pkgs; [
      asdf-vm
      gcc
      gnumake
      unzip
      update-nix-fetchgit

      ghostscript
      openssl
      python39
      mongosh

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
        NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
          stdenv.cc.cc

          # playwright
          alsa-lib
          at-spi2-atk
          cairo
          cups
          dbus
          expat
          glib
          libdrm
          libxkbcommon
          mesa
          nspr
          nss
          pango
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          xorg.libxcb
          libudev0-shim

          # puppeteer
          xorg.libxshmfence
        ];
        NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

        FZF_DEFAULT_COMMAND = "rg --files --hidden --glob '!.git' --glob '!.yarn/cache'";
        PATH = "/home/drew/.dotfiles/bin:$PATH";
        GS4JS_HOME = "${pkgs.ghostscript}/lib";
      };
      shellAliases = {
        n = "nvim";
        tm = "tmux attach || tmux new";
        cat = "bat";

        ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir";
        tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir";
        tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";

        mongo = "mongosh";
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
        rev = "9d37797e6f9856ef25cfa266cff43f764e828827"; # refs/heads/v2.0
        sha256 = "0a57bswr6w0nmxj1fmvn24w60ibgh1gyqx586qhz1fq5i4jfjva8";
      };
      recursive = true;
    };

    home.file.".config/nvim/lua/custom" = {
      source = ./nvchad-custom;
      recursive = true;
    };

    home.file.".tool-versions".text = ''
      nodejs 20.9.0
    '';

    home.file.".asdfrc".text = ''
      legacy_version_file = yes
    '';

    home.stateVersion = "23.05";
  };

  system.stateVersion = "23.05";
}
