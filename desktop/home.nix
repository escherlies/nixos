{
  # config,
  pkgs,
  ...
}:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "enrico";
  home.homeDirectory = "/home/enrico";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.vscode.enable = true;
  programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
    # Languages
    jnoortheen.nix-ide
    nefrob.vscode-just-syntax
    elmtooling.elm-ls-vscode

    # Tooling
    usernamehw.errorlens
    eamodio.gitlens

    # Themes
    catppuccin.catppuccin-vsc

    # Markdown
    yzhang.markdown-all-in-one
    yzane.markdown-pdf
    bierner.markdown-mermaid
    bierner.markdown-preview-github-styles

    # Agents
    saoudrizwan.claude-dev
    rooveterinaryinc.roo-cline

    # Misc
    adpyke.codesnap

    # TODO: Add to nixpkgs https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/editors/vscode/extensions
    # jameslan.yaclock
    # gxl.git-graph-3
    # alekangelov.alek-kai-theme
    # mathematic.vscode-pdf
    # liangqin.quick-notes
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil

    # Apps
    signal-desktop
    onlyoffice-desktopeditors
  ];

  programs.alacritty = {
    enable = true;

    # https://alacritty.org/config-alacritty.html
    settings = {
      scrolling.history = 10000;

      env.TERM = "xterm-256color";

      window.padding = {
        x = 3;
        y = 3;
      };

      font.size = 10;

      cursor.style = "Beam";

      selection.save_to_clipboard = true;

    };
  };

  programs.zellij.enable = true;
  programs.zellij.settings = {
    default_shell = "fish";
  };

  services.nextcloud-client.enable = true;
}
