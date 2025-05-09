{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil

    # Apps
    signal-desktop
    onlyoffice-desktopeditors
  ];

  services.nextcloud-client.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
    ];

}
