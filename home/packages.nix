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

    tor-browser
    gh
    biome
    nodejs

    vlc

    # Needs networking.firewall.checkReversePath = "loose";
    proton-vpn

    deja-dup
    # Broken upstream: wrapGAppsHook fails with "wrapGAppsHookHasRunForOutput:
    # bad array subscript" ($output unset when the hook runs).
    # mongodb-compass

    wakeonlan

    firefox-devedition

    bun
    drawio
    mise
    # No `oauth2` cargo feature since himalaya 2.0.0 — XOAUTH2/OAUTHBEARER are
    # unconditional now, so the default feature set already covers IMAP+SMTP.
    himalaya
    ffmpeg
    broot
    viu
    serie
    gitui
    blender
    gradia

    # Photography — Lightroom-style raw workflow (reads DNG natively).
    # Uses the amdgpu OpenCL runtime enabled in machines/framework for
    # accelerated darkroom processing.
    darktable
  ];

  services.nextcloud-client.enable = true;

  nixpkgs.config.allowUnfree = true;
}
