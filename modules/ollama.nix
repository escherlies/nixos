{ config, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "0.0.0.0";
  };

  services.ollama.openFirewall = true;

  # Use reverse proxy
  services.caddy.virtualHosts."http://${config.network.services.ollama.dns}".extraConfig =
    "reverse_proxy 127.0.0.1:11434";
}
