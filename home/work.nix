{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    awscli2
    docker-compose
    ghostscript
    kubectl
    mkcert
    nginx
    openssl
    pm2
    python3
    mongosh
    yarn
    zip
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
          libgbm
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
          systemd
          # libGL

          # puppeteer
          xorg.libxshmfence
        ];
    };
    initContent = ''
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export GS4JS_HOME=${pkgs.ghostscript}/lib
    '';
    shellAliases = {
      ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-disable-bucket-update --terragrunt-working-dir";
      tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-disable-bucket-update --terragrunt-working-dir";
      tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";

      pk = "pm2 kill";
      pst = "pm2 start";
      pl = "pm2 log";
      pw = "export WORKTREE=$(ls ~/Code/qwilr | fzf)";

      wtsu = "f() { npx nodemon --ext ts,tsx --exec \"yarn test:single-unit $1\" };f";

      initq = "cp ../master/.env . && cp ../master/pages/.dev.vars pages && cp ../master/nginx/ssl/* nginx/ssl && ./install-all.sh";

      mongo = "mongosh";
    };
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
}
