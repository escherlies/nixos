{ config, ... }:

{
  imports = [
    ./service-networking.nix
    ./machines.nix
  ];

  network.services = {
    home-assistant = {
      ip = config.machines.home-server.ipv4;
      dns = "hoa.internal";
    };
    grafana = {
      ip = config.machines.home-server.ipv4;
      dns = "grafana.internal";
    };
    ollama = {
      ip = config.machines.desktop.ipv4;
      dns = "ollama.internal";
    };
    open-webui = {
      ip = config.machines.desktop.ipv4;
      dns = "ai.internal";
    };
  };
}
