{ pkgs, ... }:
{
  programs.chromium.enable = true;

  programs.chromium.package = pkgs.brave;

  programs.chromium.nativeMessagingHosts = [
    pkgs.kdePackages.plasma-browser-integration

  ];

}
