{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil

    # Apps
    signal-desktop

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
    # shell-gpt
    aichat
    claude-code
    gemini-cli

    tor-browser
    gh
    biome
    nodejs

    vlc

    # Needs networking.firewall.checkReversePath = "loose";
    protonvpn-gui

    deja-dup
    mongodb-compass

    wakeonlan
  ];

  services.nextcloud-client.enable = true;

  nixpkgs.config.allowUnfree = true;
}
