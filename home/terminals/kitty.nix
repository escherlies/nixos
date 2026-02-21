{
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

      confirm_os_window_close = 0;
    };

    keybindings = {
      "ctrl+shift+enter" = "launch --cwd=current";
      "ctrl+shift+t" = "new_tab";
    };
  };
}
