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

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    signal-desktop

    nixfmt-rfc-style
    nil
  ];

  programs.alacritty = {
    enable = true;
    settings = {

      scrolling.history = 10000;
      env.TERM = "xterm-256color";

      window = {
        # dimensions = {
        #   lines = 40;
        #   columns = 120;
        # };
        padding = {
          x = 3;
          y = 3;
        };
      };

      font = {
        size = 10;
      };

      cursor = {
        style = "Beam";
      };

    };
  };

  programs.zellij.enable = true;
  programs.zellij.settings = {
    default_shell = "fish";
  };

  services.nextcloud-client.enable = true;
}
