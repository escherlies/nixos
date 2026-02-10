{ config, ... }:

{
  imports = [
    ./service-networking.nix
    ./machines.nix
  ];

  network.services = {
    home-assistant = {
      ip = config.machines.home-server.ipv4;
      dns = "hoa.lan";
    };
    grafana = {
      ip = config.machines.home-server.ipv4;
      dns = "grafana.lan";
    };
    ollama = {
      ip = config.machines.desktop.ipv4;
      dns = "ollama.lan";
    };
    open-webui = {
      ip = config.machines.desktop.ipv4;
      dns = "ai.lan";
    };
    example = {
      ip = config.machines.home-server.ipv4;
      dns = "example.lan";
    };
  };
}
