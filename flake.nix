{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

  };

  outputs = { self, ... }@inputs:
    with inputs; {
      nixosConfigurations = {

        base = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./configuration.nix ];
        };

        test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./configs/test.nix

          ];
        };

        tunneln = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./configs/ssh-gateway-ports.nix

          ];
        };

        web-services = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./configs/web-services.nix

          ];
        };

        docker-compose = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./configs/docker-compose.nix

          ];
        };

      };

    };
}
