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

      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty";

      # Use xterm-256color so less (and other TUI apps) handle keys correctly
      term = "xterm-256color";

      # Jump to end of scrollback with +G instead of +INPUT_LINE_NUMBER
      # to avoid blank white screen when opening the pager
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +G";
    };

    keybindings = {
      "ctrl+shift+enter" = "launch --cwd=current";
      "ctrl+shift+t" = "new_tab";
    };
  };
}
