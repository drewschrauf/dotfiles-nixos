{ lib, pkgs, ... }:
{
  imports = [
    ./shared.nix
  ];

  environment.systemPackages = with pkgs; [
    nginx
  ];

  home-manager.users.drew = { pkgs, ... }: {
    home.packages = with pkgs; [
      awscli
      ghostscript
      openssl
      python39
      mongosh
    ];

    programs.zsh = {
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
      };
      shellAliases = {
        ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir";
        tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir";
        tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";

        mongo = "mongosh";
      };
    };
  };
}
