{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  };

  outputs =
    { self, nixpkgs, ... }@inputs:

    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

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

      # Add dependencies that are only needed for development
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ nixos-rebuild ];
          };
        }
      );

      nixosConfigurations = {

        base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/hcloud.nix
            ./configuration.nix
          ];
        };

        vultr-base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/vultr.nix
            ./configuration.nix
          ];
        };

        test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/hcloud.nix
            ./configuration.nix
            ./configs/test.nix
          ];
        };

        tunneln = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/hcloud.nix
            ./configuration.nix
            ./configs/ssh-gateway-ports.nix
          ];
        };

        web-services = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/hcloud.nix
            ./configuration.nix
            ./configs/web-services.nix
          ];
        };

        docker-compose = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/hcloud.nix
            ./configuration.nix
            ./configs/docker-compose.nix
          ];
        };
      };
    };
}
