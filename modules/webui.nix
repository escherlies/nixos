{ config, ... }:
{
  services.open-webui = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };

  # Use reverse proxy with internal TLS issuer
  services.caddy.virtualHosts."${config.network.services.open-webui.dns}".extraConfig = ''
    tls internal
    reverse_proxy 127.0.0.1:8080
  '';
}
