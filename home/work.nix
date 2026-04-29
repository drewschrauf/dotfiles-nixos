{pkgs, ...}: {
  home.packages = with pkgs; [
    awscli2
    ghostscript
    kubectl
    mkcert
    nssTools
    openssl
    pm2
    python3
    mongosh
    yarn
    zip
  ];

  programs.zsh = {
    initContent = ''
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
