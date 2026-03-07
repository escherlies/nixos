{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/wireguard.nix
    ../../modules/ssh.nix
  ];

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

  # Minimal packages
  environment.systemPackages = [ ];
}
