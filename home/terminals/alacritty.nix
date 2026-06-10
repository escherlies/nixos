{
  config,
  pkgs,
  ...
}:
{
  programs.alacritty = {
    enable = true;

    # https://alacritty.org/config-alacritty.html
    settings = {
      # Theme is not hardcoded here: Alacritty has no native dark/light
      # auto-switching, so the active theme is a separate file swapped at
      # runtime by the `dark-mode` CLI. Alacritty live-reloads on the change.
      general.import = [
        "${config.home.homeDirectory}/.config/alacritty/theme.toml"
      ];
      general.live_config_reload = true;

      scrolling.history = 10000;

      env.TERM = "xterm-256color";

      window.padding = {
        x = 3;
        y = 3;
      };

      window.dynamic_title = true;
      window.option_as_alt = "Both"; # Option key acts as Alt on macOS

      font.size = 10;

      cursor.style = "Beam";

      selection.save_to_clipboard = true;

    };
  };

  # Make the committed themes available for the `dark-mode` CLI to switch
  # between (it copies the chosen one to ~/.config/alacritty/theme.toml).
  xdg.configFile."alacritty/themes".source = ./alacritty;
}
