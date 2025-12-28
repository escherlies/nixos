{ config, lib, ... }:
{
  programs.starship = {
    enable = true;

    presets = [
      "catppuccin-powerline"
      "nerd-font-symbols"
    ];

    settings =
      let
        mkLanguageModule = {
          format = "[ via $version]($style)";
          style = "fg:crust bg:green";
        };

        languages = [
          "elm"
          "purescript"
          "bun"
          "deno"
          "rust"
          "golang"
          "nodejs"
          "haskell"
        ];
        languageModules = lib.genAttrs languages (_: mkLanguageModule);
      in
      languageModules
      // {
        add_newline = true;
        cmd_duration.show_notifications = false;
        cmd_duration.min_time = 50;

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

        hostname = {
          ssh_only = true;
          format = "[@$hostname]($style)";
          style = "fg:crust bg:red";
        };

        format =
          let
            languages = "$elm$purescript$bun$deno$rust$golang$nodejs$haskell";

            default-colors = {
              red = "red";
              peach = "peach";
              yellow = "yellow";
              green = "green";
              sapphire = "sapphire";
              lavender = "lavender";
            };

            grayscale-colors = {
              red = "#e6e6e6"; # Very light gray
              peach = "#d9d9d9"; # Light gray
              yellow = "#cccccc"; # Medium-light gray
              green = "#bfbfbf"; # Medium gray
              sapphire = "#b3b3b3"; # Medium-dark gray
              lavender = "#a6a6a6"; # Dark gray
            };

            colors = if config.networking.hostName == "desktop" then grayscale-colors else default-colors;

            sections = lib.strings.concatStrings [
              # Red section
              "[](${colors.red})"
              "$os$username$hostname[](bg:${colors.peach} fg:${colors.red})"

              # Orange
              "$directory[](bg:${colors.yellow} fg:${colors.peach})"

              # Yellow
              "$git_branch$git_status[](fg:${colors.yellow} bg:${colors.green})"

              # Green
              "${languages}[](fg:${colors.green} bg:${colors.sapphire})"

              # Blue
              "$nix_shell[](fg:${colors.sapphire} bg:${colors.lavender})"

              # Purple
              "$time[](fg:${colors.lavender})"

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
