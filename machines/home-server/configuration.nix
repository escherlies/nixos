{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/blocky.nix
    ../../modules/monitoring.nix
    ../../modules/machines.nix
    ../../modules/wol-gateway.nix
  ];

  boot.loader.grub = {
    enable = true;
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  users.users.enrico = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$uapzMYRLnAbVkSEB8r5jW0$J7Uc0KUMWVbAQL1TjHRsZTa8uUYei4EEJnOzgGVD9f9";
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIsi0Q1fnYWAmJwPT/FeNqShZgn4z/23APCpazZmTcQ enrico@framework"
  ];

  users.users.enrico.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIsi0Q1fnYWAmJwPT/FeNqShZgn4z/23APCpazZmTcQ enrico@framework"
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Wake-on-LAN: allows waking desktop from remote machines via VPN
  environment.systemPackages = [ pkgs.wakeonlan ];

  system.stateVersion = "25.11";

  networking.hostName = "home-server";
  networking.useDHCP = true;

  server.metadata.ipv4 = config.machines.home-server.ipv4;

  # Enable Caddy for reverse proxy
  services.caddy.enable = true;

  # Enable WireGuard VPN
  vpn.enable = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # WoL gateway: wake the desktop on-demand when accessing its services.
  # Desktop services DNS (ollama.lan, ai.lan, opencode.desktop.lan) resolves
  # to the home-server. Caddy here proxies to the desktop, waking it first
  # via Wake-on-LAN if it's suspended.
  services.wol-gateway = {
    enable = true;
    target = {
      ip = config.machines.desktop.vpnIp; # 10.100.0.3
      mac = "d8:43:ae:8e:88:0b";
      checkPort = 22; # SSH comes up fast after resume
    };
    proxiedServices = {
      ollama = {
        dns = "ollama.lan";
        targetPort = 11434;
      };
      open-webui = {
        dns = "ai.lan";
        targetPort = 8080;
      };
      opencode-desktop = {
        dns = "opencode.desktop.lan";
        targetPort = 4097;
      };
    };
  };
}
