{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  };

  outputs = { self, ... }@inputs:
    with inputs; {
      nixosConfigurations = {

        my-hetzner-host = nixpkgs.lib.nixosSystem {

          system = "x86_64-linux";

          modules = [ ./configuration.nix ];
        };
      };
    };
}
