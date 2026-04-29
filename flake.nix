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

      {
        nixpkgs.config.allowUnfree = true;
      }

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
    homeConfigurations.drew = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit secrets;};
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          home.username = "drew";
          home.homeDirectory = "/home/drew";
        }
        ./home/default.nix
        ./home/work.nix
      ];
    };

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
          ./nixos/work.nix
          {
            networking.hostName = "work";
            home-manager.users.drew = import ./home/work.nix;
          }
        ];
    };
  };
}
