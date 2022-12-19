{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.hostName = "nixe";
  security.acme.defaults.email = "escherlies@pm.me";
  security.acme.acceptTerms = true;
  services.nginx.enable = true;

  # First nixos test page :)
  services.nginx.virtualHosts."static.68.125.88.23.clients.your-server.de" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/static.68.125.88.23.clients.your-server.de";
  };

  # Binary Please
  services.nginx.virtualHosts."www.binaryplease.com" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/binary-please";
  };
  services.nginx.virtualHosts."binaryplease.com" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/binary-please";
  };
}
