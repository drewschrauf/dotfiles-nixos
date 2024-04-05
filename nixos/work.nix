{...}: {
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  system.activationScripts.binbash = {
    deps = ["binsh"];
    text = ''
      ln -sfn /bin/sh /bin/bash
    '';
  };

  users.users.drew = {
    extraGroups = ["docker"];
  };
}
