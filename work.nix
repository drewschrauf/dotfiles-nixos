{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nginx
  ];

  home-manager.users.drew = { pkgs, ... }: {
    home.packages = with pkgs; [
      ghostscript
      openssl
      python39
      mongosh
    ];

    programs.zsh = {
      shellAliases = {
        ta = "terragrunt run-all apply --terragrunt-non-interactive --terragrunt-working-dir";
        tp = "terragrunt run-all plan --terragrunt-non-interactive --terragrunt-working-dir";
        tdel = "find . -name '.terra*' -type d -print | xargs rm -rf";

        mongo = "mongosh";
      };
    };
  };
}
