{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil

    # Apps
    signal-desktop-bin # As of 2025-05-14 the nixpkg build is broken: no devices found
    onlyoffice-desktopeditors

    # Audio
    pavucontrol
    comma

    # Wayland utils
    wl-clipboard

    # Utils
    yt-dlp # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)
    scdl # Download Music from Soundcloud

    micro

    #
    shell-gpt
    claude-code
    gemini-cli

    tor-browser
    gh
    biome

    vlc

    # Needs networking.firewall.checkReversePath = "loose";
    protonvpn-gui
  ];

  services.nextcloud-client.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
    ];

}
