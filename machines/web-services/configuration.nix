{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../modules/default.nix

    ./web-services.nix
    ./stripe-datev-exporter.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  boot.tmp.cleanOnBoot = true;

  zramSwap.enable = true;

  networking.hostName = "web-services";

  # TODO Split users. Reason: We need a user if we define users.users.enrico.openssh.authorizedKeys.keys.
  users.users.enrico = {
    isNormalUser = true;
    description = "enrico";
    extraGroups = [
      "wheel"
      "docker"
    ];
  };

}
