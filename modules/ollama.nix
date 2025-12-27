{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
  };

  services.ollama.openFirewall = true;
}
