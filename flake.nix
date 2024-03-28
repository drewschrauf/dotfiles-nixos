{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "github:input-output-hk/empty-flake";
    };
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    home-manager,
    secrets,
    ...
  }: let
    sharedModules = [
      ./nixos/default.nix

      nixos-wsl.nixosModules.wsl
      {
        wsl.enable = true;
        wsl.defaultUser = "drew";
      }

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.extraSpecialArgs = {inherit secrets;};
        home-manager.users.drew = import ./home/default.nix;
      }
    ];
  in {
    nixosConfigurations.personal = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit secrets;};
      modules =
        sharedModules
        ++ [
          {
            networking.hostName = "personal";
            home-manager.users.drew = import ./home/personal.nix;
          }
        ];
    };
    nixosConfigurations.work = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit secrets;};
      modules =
        sharedModules
        ++ [
          {
            networking.hostName = "work";
            home-manager.users.drew = import ./home/work.nix;
          }
        ];
    };
  };
}
