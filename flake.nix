{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:

    let
      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      # Modules
      nixosModules.core =
        { config, ... }:
        {
          imports = [
            ./modules/core.nix
          ];
          options = { };
          config = { };
        };

      # Add dependencies that are only needed for development
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell { buildInputs = with pkgs; [ nixos-rebuild ]; };
        }
      );

      nixosConfigurations = {

        web-services = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/web-services/configuration.nix
          ];
        };

        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/desktop/configuration.nix
            ./machines/desktop/hardware-configuration.nix
            ./modules/default.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.enrico = ./home/default.nix;

              # Disabled for now. Let home-manager fail so i know i had some dotfiles flying around
              # home-manager.backupFileExtension = "_bk";

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };

        laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/laptop/configuration.nix
            ./machines/laptop/hardware-configuration.nix
            ./modules/default.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.enrico = ./home/default.nix;
              # home-manager.backupFileExtension = "_bk";

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };

        framework = nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          system = "x86_64-linux";
          modules = [
            ./machines/framework/configuration.nix
            ./modules/default.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.enrico = ./home/default.nix;
              # home-manager.backupFileExtension = "_bk";

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };
      };
    };
}
