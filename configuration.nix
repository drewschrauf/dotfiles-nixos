{ lib, pkgs, ... }:
let
  nix-alien-pkgs = import (
    pkgs.fetchFromGitHub {
      owner = "thiagokokada";
      repo = "nix-alien";
      rev = "80ee1d14570b9a316a8cf237be8368a910ed826f";
      sha256 = "1pkfbkkcwjaqgvvrascdc0yf95n1qx1p2wgjb9w5yh4axhn6wjqn";
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

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  environment.systemPackages = with nix-alien-pkgs; [
    nix-alien
  ];

  users.users.drew = {
    shell = pkgs.zsh;
    extraGroups = [ "docker" ];
  };

  home-manager.users.drew = { pkgs, ... }: {
    home.packages = with pkgs; [
      asdf-vm
      bash
      gcc
      gnumake
      python3
      unzip
      update-nix-fetchgit

      ghostscript

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
        ];
        NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

        FZF_DEFAULT_COMMAND = "rg --files --hidden --glob '!.git' --glob '!esy.lock' --glob '!.yarn/cache'";
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
        rev = "fd10af115e0507b3976d78123eda9748fe0e2d29"; # refs/heads/v2.0
        sha256 = "0ar0yfsnq9i708xxcv3c1y25n7q8xl7mfki62vrva2nz72nyjrzc";
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
