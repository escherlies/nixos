{ config, lib, ... }:
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

        nix_shell = {
          format = "[ $symbol$state( \\($name\\))]($style)";
          style = "fg:crust bg:sapphire";
        };

        git_status = {
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          behind = "⇣\${count}";
          stashed = "";
        };

        format =
          let
            languages = "$elm$purescript$bun$deno$rust$golang$nodejs$haskell";
            sections = lib.strings.concatStrings [
              # Red section
              "[](red)"
              "$os$username[](bg:peach fg:red)"

              # Orange
              "$directory[](bg:yellow fg:peach)"

              # Yellow
              "$git_branch$git_status[](fg:yellow bg:green)"

              # Green
              "${languages}[](fg:green bg:sapphire)"

              # Blue
              "$nix_shell[](fg:sapphire bg:lavender)"

              # Purple
              "$time[](fg:lavender)"

              #
              " $cmd_duration"
            ];
          in
          ''
            ┌${sections}
            └─$character'';
        # Example: change prompt symbol
        character = {
          success_symbol = "λ";
          error_symbol = "λ";
        };
      };
  };
}
