{ nixpkgs-stable, pkgs, ... }:
{
  services.open-webui = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
    package = nixpkgs-stable.legacyPackages.${pkgs.system}.open-webui;
  };
}
