{pkgs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  programs.zsh.enable = true;
  users.users.drew = {
    shell = pkgs.zsh;
  };

  system.stateVersion = "23.05";
}
