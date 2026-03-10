{ config, ... }:

{
  imports = [
    ./service-networking.nix
    ./machines.nix
  ];

  network.services = {
    home-assistant = {
      ip = config.machines.home-server.ipv4;
      machine = "home-server";
      dns = "hoa.lan";
      wgDns = "hoa.wg";
    };
    grafana = {
      ip = config.machines.home-server.ipv4;
      machine = "home-server";
      dns = "grafana.lan";
      wgDns = "grafana.wg";
    };
    ollama = {
      ip = config.machines.desktop.ipv4;
      machine = "desktop";
      dns = "ollama.lan";
      wgDns = "ollama.wg";
    };
    open-webui = {
      ip = config.machines.desktop.ipv4;
      machine = "desktop";
      dns = "ai.lan";
      wgDns = "ai.wg";
    };
    opencode-desktop = {
      ip = config.machines.desktop.ipv4;
      machine = "desktop";
      dns = "opencode.desktop.lan";
      wgDns = "opencode.desktop.wg";
    };
    opencode-framework = {
      ip = config.machines.framework.ipv4;
      machine = "framework";
      dns = "opencode.framework.lan";
      wgDns = "opencode.framework.wg";
    };
    example = {
      ip = config.machines.home-server.ipv4;
      machine = "home-server";
      dns = "example.lan";
      wgDns = "example.wg";
    };
  };
}
