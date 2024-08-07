{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.hostName = "nixe";

  # Plain websites

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

  services.nginx.virtualHosts."enryco.xyz" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/blog";
  };

  # Docker services

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs;
    [
      docker-compose

    ];

  users.users.root.extraGroups = [ "docker" ];

  # Use NGINX as reverse proxy

  services.nginx.recommendedProxySettings = true;
  services.nginx.recommendedTlsSettings = true;

  # Nononote
  services.nginx.virtualHosts."nononote.ai" = {
    enableACME = true;
    forceSSL = true;
    root = "/var/www/nononote";

    locations."/api" = {
      proxyPass = "http://127.0.0.1:8000/api";
      proxyWebsockets = true;
      extraConfig =
        # required when the server wants to use HTTP Authentication
        "proxy_pass_header Authorization;";
    };

    locations."/auth" = {
      proxyPass = "http://127.0.0.1:8000/auth";
      proxyWebsockets = false;
      extraConfig =
        # required when the server wants to use HTTP Authentication
        "proxy_pass_header Authorization;";
    };

    locations."/" = {
      extraConfig = ''
        try_files $uri /index.html;
      '';
    };
  };

}
