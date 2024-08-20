{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    asdf-vm
    awscli
    ghostscript
    nginx
    openssl
    python39
    mongosh
  ];

  programs.zsh = {
    localVariables = {
      NIX_LD_LIBRARY_PATH = with pkgs;
        lib.makeLibraryPath [
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
      GS4JS_HOME = "${pkgs.ghostscript}/lib";
    };
    initExtra = ''
      . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh
      export RPROMPT='$''\{WORKTREE}'
    '';
    shellAliases = {
      ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir";
      tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir";
      tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";

      pk = "pm2 kill";
      pst = "pm2 start";
      pl = "pm2 log";
      pw = "f() { export WORKTREE=$1 };f";

      wtsu = "f() { npx nodemon --ext ts --exec \"yarn test:single-unit $1\" };f";

      initq = "cp ../master/.env . && cp ../master/pages/.dev.vars pages && cp ../master/nginx/ssl/* nginx/ssl && GS4JS_HOME=$GS4JS_HOME ./install-all.sh";

      mongo = "mongosh";
    };
  };

  home.file.".asdfrc".text = ''
    legacy_version_file = yes
  '';

  home.file.".tool-versions".text = ''
    nodejs 20.9.0
  '';
}
