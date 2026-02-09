{ config, ... }:
{
  services.open-webui = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };

  # Use reverse proxy
  services.caddy.virtualHosts."http://${config.network.services.open-webui.dns}".extraConfig =
    "reverse_proxy 127.0.0.1:8080";
}
