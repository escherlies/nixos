{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil

    # Apps
    signal-desktop-bin # As of 2025-05-14 the nixpkg build is broken: no devices found
    onlyoffice-desktopeditors
  ];

  services.nextcloud-client.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
    ];

}
