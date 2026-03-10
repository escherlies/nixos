{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/wireguard.nix
    ../../modules/vpn-dns.nix
    ../../modules/ssh.nix
  ];

  boot.loader.grub = {
    enable = true;
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  system.stateVersion = "24.11";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  networking.hostName = "vpn-gateway";

  users.users.enrico = {
    isNormalUser = true;
    description = "enrico";
    extraGroups = [ "wheel" ];
  };

  # Enable WireGuard VPN hub
  vpn.enable = true;

  # Nix essentials for a long-running server
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };
  nix.settings.auto-optimise-store = true;

  # Minimal packages
  environment.systemPackages = [ ];
}
