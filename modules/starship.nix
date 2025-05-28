{ config, ... }:
{
  programs.starship = {
    enable = true;

    presets = [
      "catppuccin-powerline"
      "nerd-font-symbols"
    ];

    settings =

      {
        add_newline = true;
        cmd_duration.show_notifications = false;

        format =
          let
            languages = "$c$rust$golang$nodejs$php$java$kotlin$haskell$python";
          in
          ''
            ┌[](red)$os$username[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)${languages}[](fg:green bg:sapphire)$conda[](fg:sapphire bg:lavender)$time[](fg:lavender) $cmd_duration
            └─$character'';
        # Example: change prompt symbol
        character = {
          success_symbol = "λ";
          error_symbol = "λ";
        };
      };
  };
}
