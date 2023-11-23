{ ... }:
{
  imports = [
    ./shared.nix
  ];

  home-manager.users.drew = { pkgs, ... }: {
    programs.zsh = {
      localVariables = {
        NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
          stdenv.cc.cc
        ];
      };
    };
  };
}
