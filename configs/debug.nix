{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.hostName = "nix-debug";

  services.nginx.enable = true;

  # First nixos test page :)
  services.nginx.virtualHosts.localhost = {
    root = "/var/www";
  };

  # Floating IP
  networking.localCommands = ''
    ip addr add 5.75.209.107 dev enp1s0
  '';
}