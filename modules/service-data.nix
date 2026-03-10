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
    # Desktop services: DNS points to home-server, which runs the WoL gateway proxy.
    # When accessed, the home-server wakes the desktop (if suspended) and proxies through.
    ollama = {
      ip = config.machines.home-server.ipv4;
      dns = "ollama.lan";
    };
    open-webui = {
      ip = config.machines.home-server.ipv4;
      dns = "ai.lan";
    };
    opencode-desktop = {
      ip = config.machines.home-server.ipv4;
      dns = "opencode.desktop.lan";
    };
    opencode-framework = {
      ip = config.machines.framework.ipv4;
      dns = "opencode.framework.lan";
    };
    example = {
      ip = config.machines.home-server.ipv4;
      dns = "example.lan";
    };
  };
}
