{ config, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "0.0.0.0";
  };

  services.ollama.openFirewall = true;

  # Use reverse proxy with internal TLS issuer
  services.caddy.virtualHosts."${config.network.services.ollama.dns}".extraConfig = ''
    tls internal
    reverse_proxy 127.0.0.1:11434
  '';
}
