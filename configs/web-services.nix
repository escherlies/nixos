{
  security.acme.defaults.email = "escherlies@pm.me";
  security.acme.acceptTerms = true;
  services.nginx.enable = true;
  services.nginx.virtualHosts."static.68.125.88.23.clients.your-server.de" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/static.68.125.88.23.clients.your-server.de";
  };
}
