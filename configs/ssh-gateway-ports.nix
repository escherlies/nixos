{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.openssh.gatewayPorts = "yes";
}
