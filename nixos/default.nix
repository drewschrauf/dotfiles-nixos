{pkgs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

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

  system.stateVersion = "23.05";
}
