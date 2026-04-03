{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/blocky.nix
    ../../modules/monitoring.nix
    ../../modules/machines.nix
    ../../modules/protonvpn.nix
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

  # Enable WireGuard VPN mesh
  vpn.enable = true;

  # ProtonVPN gateway — routes all LAN traffic through ProtonVPN
  # To enable:
  # 1. Go to https://account.protonvpn.com/ > Downloads > WireGuard > Platform: Router
  # 2. Generate a config and extract the values below
  # 3. Create the secret:
  #    echo "YOUR_PRIVATE_KEY" | ragenix -e secrets/protonvpn.key.age
  # 4. Fill in address, publicKey, and endpoint below, set enable = true
  # 5. On Fritz.Box: set home-server (192.168.178.134) as the default gateway
  #    for LAN devices (Network > Network Settings > IPv4 Routes)
  protonvpn = {
    enable = false; # Set to true after completing steps above
    privateKeyFile = config.age.secrets.protonvpn.path;
    address = "CHANGE_ME"; # e.g. "10.2.0.2/32" — from ProtonVPN config [Interface] Address
    peer = {
      publicKey = "CHANGE_ME"; # from ProtonVPN config [Peer] PublicKey
      endpoint = "0.0.0.0:51820"; # e.g. "185.159.158.1:51820" — from ProtonVPN config [Peer] Endpoint
    };
    lanInterface = "eno1";
    lanSubnet = "192.168.178.0/24";
  };

  # Uncomment when protonvpn.enable = true
  # age.secrets.protonvpn = {
  #   file = ../../secrets/protonvpn.key.age;
  #   mode = "0400";
  # };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
