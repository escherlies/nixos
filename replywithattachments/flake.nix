{
  description = "rwa nixos config";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11"; };

  outputs = { self, ... }@inputs:
    with inputs; {
      nixosConfigurations = {

        staging = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ({ lib, ... }: {
              machine.subdomain = "staging";

            })
          ];
        };

        production = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ({ lib, ... }: {

              machine.subdomain = "app";

            })
          ];
        };

      };

    };
}
