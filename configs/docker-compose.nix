{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.hostName = "nixe-2";

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs;
    [
      docker-compose

    ];

  users.users.root.extraGroups = [ "docker" ];

  # Use NGINX as reverse proxy
  security.acme.defaults.email = "escherlies@pm.me";
  security.acme.acceptTerms = true;
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # other Nginx options
    virtualHosts."static.185.215.12.49.clients.your-server.de" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
        proxyWebsockets = true;
        extraConfig =
          # required when the server wants to use HTTP Authentication
          "proxy_pass_header Authorization;";
      };
    };
  };
}
