{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  };

  outputs = { self, ... }@inputs:
    with inputs; {
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
            ./hardware/hcloud.nix
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
