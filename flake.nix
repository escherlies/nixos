{
  description = "My machines";

  inputs = {
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:

    let
      # Relative path from $HOME to this repo checkout.
      # Used by home-manager (mkOutOfStoreSymlink) and NixOS activation scripts
      # to create symlinks into the working tree rather than the Nix store.
      repoSubdir = "Developer/nixos";

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
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              hello
              ragenix
              bash # VS Code shell integration injects \[...\] readline non-printing markers into PS1; without bash in PATH from the nix store, these are not interpreted and render as literal garbage
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt);

      nixosConfigurations = {

        vpn-gateway = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.disko.nixosModules.disko
            inputs.agenix.nixosModules.default
            ./machines/vpn-gateway/configuration.nix
          ];
        };

        web-services = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/web-services/configuration.nix
          ];
        };

        home-server = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit repoSubdir; };
          system = "x86_64-linux";
          modules = [
            inputs.disko.nixosModules.disko
            inputs.agenix.nixosModules.default
            ./machines/home-server/configuration.nix
            ./modules/default.nix
            ./modules/home-assistant.nix
            ./modules/caddy-pki.nix
            ./modules/wireguard.nix
          ];
        };

        desktop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit repoSubdir; };
          system = "x86_64-linux";
          modules = [
            { nixpkgs.overlays = [ inputs.opencode.overlays.default ]; }
            inputs.agenix.nixosModules.default
            ./machines/desktop/configuration.nix
            ./machines/desktop/hardware-configuration.nix
            ./modules/default.nix
            ./configs/graphical.nix
            ./modules/docker.nix
            ./modules/caddy-pki.nix
            ./modules/user-env.nix
            ./modules/wireguard.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit repoSubdir; };
              home-manager.users.enrico = ./home/default.nix;

              # Disabled for now. Let home-manager fail so i know i had some dotfiles flying around
              # home-manager.backupFileExtension = "_bk";
            }
          ];
        };

        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit repoSubdir; };
          system = "x86_64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            ./machines/laptop/configuration.nix
            ./machines/laptop/hardware-configuration.nix
            ./modules/default.nix
            ./configs/graphical.nix
            ./modules/user-env.nix
            ./modules/wireguard.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit repoSubdir; };
              home-manager.users.enrico = ./home/default.nix;
              # home-manager.backupFileExtension = "_bk";
            }
          ];
        };

        framework = nixpkgs.lib.nixosSystem {
          specialArgs = inputs // {
            inherit repoSubdir;
          };
          system = "x86_64-linux";
          modules = [
            # { nixpkgs.overlays = [ inputs.opencode.overlays.default ]; }
            inputs.agenix.nixosModules.default
            ./machines/framework/configuration.nix
            ./modules/default.nix
            ./configs/graphical.nix
            ./modules/docker.nix
            ./modules/libvirt.nix
            ./modules/user-env.nix
            ./modules/wireguard.nix
            ./modules/opencode.nix
            ./modules/caddy-pki.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit repoSubdir; };
              home-manager.users.enrico = ./home/default.nix;
              # home-manager.backupFileExtension = "_bk";
            }
          ];
        };
      };
    };
}
