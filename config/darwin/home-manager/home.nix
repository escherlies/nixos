{ pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "enrico";
  home.homeDirectory = "/Users/enrico";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # Mac tools
    aldente
    monitorcontrol
    pika # Color Picker

    # Apps
    ncdu # Disk usage analyzer with an ncurses interface

    # Dev tools
    tmux
    nodejs_20
    mongodb-tools
    tokei
    just
    thefuck
    tree
    watchexec
    bash # pre-installed bash is too old
    coreutils
    git-lfs

    # Rust
    rustup

    stripe-cli

    nodePackages.nodemon
    # nodePackages.purs-tidy

    # elmPackages.elm
    # elmPackages.elm-format
    # elmPackages.elm-test-rs

    # Blogging
    zola

    # Misc
    asciiquarium-transparent

    # Nix
    nixfmt
    nil

    # Misc
    bun
    caddy
    yarn
    nixos-rebuild
    deno

    typst
    poppler_utils

    comma
    croc
  ];

  nixpkgs.config.allowUnfree = true;

  home.file = { };

  home.sessionVariables = { };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zellij.enable = true;
  programs.zellij.settings = {
    default_shell = "fish";
  };

  programs.git = {
    enable = true;
    userName = "Enrico Scherlies";
    userEmail = "e.scherlies@pm.me";
    ignores = [
      ".note.*"
      ".vscode"
      ".DS_Store"
      ".notes"
      "**/__ignore__*"

    ];

    extraConfig = {
      init.defaultBranch = "main";
    };

    difftastic.enable = true;
  };

}
