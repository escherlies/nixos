{ pkgs, lib, ... }:
let
  mdstream = pkgs.writeShellScriptBin "mdstream" (
    lib.replaceStrings [ "glow" ] [ "${pkgs.glow}/bin/glow" ] (builtins.readFile ../scripts/mdstream)
  );
  cpfile = pkgs.writeShellScriptBin "cpfile" (
    lib.replaceStrings
      [ "file -b" "xclip" ]
      [
        "${pkgs.file}/bin/file -b"
        "${pkgs.xclip}/bin/xclip"
      ]
      (builtins.readFile ../scripts/cpfile)
  );
in
{
  home.packages = with pkgs; [
    # Custom scripts
    mdstream
    cpfile

    # Nix
    nixfmt
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
    glow # Markdown renderer for the CLI
    imagemagick
    yt-dlp # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)
    scdl # Download Music from Soundcloud

    micro

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

    firefox-devedition

    bun
    drawio
    mise
    (himalaya.override {
      withFeatures = [ "oauth2" ];
    })
    ffmpeg
    broot
    viu
  ];

  services.nextcloud-client.enable = true;

  nixpkgs.config.allowUnfree = true;
}
