{
  config,
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

      # Start in ~/Developer
      startup_session = "${config.xdg.configHome}/kitty/startup.conf";
    };

    keybindings = {
      "ctrl+shift+enter" = "launch --cwd=current";
      "ctrl+shift+t" = "launch --type=tab --cwd=~/Developer";
      "ctrl+shift+n" = "launch --type=os-window --cwd=~/Developer";
      "ctrl+shift+equal" = "change_font_size current +1.0";
      "ctrl+shift+minus" = "change_font_size current -1.0";
      "ctrl+shift+0" = "change_font_size current 0";
    };
  };

  # Startup session that sets the initial working directory
  home.file.".config/kitty/startup.conf".text = ''
    cd ${config.home.homeDirectory}/Developer
  '';
}
