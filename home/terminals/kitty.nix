{
  config,
  pkgs,
  ...
}:
let
  # nixpkgs unstable is still pinned to kitty 0.47.1; 0.47.2 ships a critical
  # fix, so pin it here until the bump lands upstream. Both the source and the
  # Go module set changed between releases (go.mod/go.sum were updated), hence
  # overriding `src` *and* `goModules`. Drop this block once pkgs.kitty >= 0.47.2.
  kitty-0_47_2 = pkgs.kitty.overrideAttrs (old: rec {
    version = "0.47.2";
    src = pkgs.fetchFromGitHub {
      owner = "kovidgoyal";
      repo = "kitty";
      tag = "v${version}";
      hash = "sha256-hRQ/1EMBt04Er1OfLg1W9fIma3NZBHZklW1N4DmFBpM=";
    };
    goModules =
      (pkgs.buildGo126Module {
        pname = "kitty-go-modules";
        inherit version src;
        vendorHash = "sha256-zZZDrWzl2q/o4f52diE0YDV/MdYfsdKWWjQ0ej2bBTM=";
      }).goModules;
    # 0.47.2's go.mod bumps the toolchain directive to go1.26.4, but nixpkgs
    # ships go 1.26.3. Force the local toolchain (the go directive only needs
    # 1.26.0) so the build doesn't try to download go1.26.4 in the sandbox.
    env = old.env // {
      GOTOOLCHAIN = "local";
    };
  });
in
{
  programs.kitty = {
    enable = true;
    package = kitty-0_47_2;
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
