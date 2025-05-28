{
  lib,
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    font.name = "FiraCode Nerd Font";
    font.size = 10;

    settings = {
      window_padding_width = 20;
      window_padding_height = 20;
      #   macos_option_as_alt = true; # Option key acts as Alt on macOS
      #   enable_audio_bell = false;
      tab_bar_edge = "top"; # tab bar on top
      copy_on_select = true;
      # Remove Micro conflicting keymaps
      "map ctrl+shift+right" = "none";
      "map ctrl+shift+left" = "none";
      "map ctrl+shift+enter" = "none";
    };
  };
}
