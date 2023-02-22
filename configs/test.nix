{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  networking.hostName = "nix-test";

  services.nginx.enable = true;

  # First nixos test page :)
  services.nginx.virtualHosts.localhost = { root = "/var/www"; };
}
