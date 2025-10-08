{ ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
  };

  services.ollama.openFirewall = true;
}
