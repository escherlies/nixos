{
  # config,
  pkgs,
  ...
}:
{
  programs.alacritty = {
    enable = true;

    # https://alacritty.org/config-alacritty.html
    settings = {
      general.import = [
        ./alacritty/catppuccin-mocha.toml
      ];

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

}
