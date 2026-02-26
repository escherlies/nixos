{ lib, ... }:
{
  programs.starship = {
    enable = true;

    presets = [
      "nerd-font-symbols"
    ];

    settings =
      let
        palette = {
          bg = "#201d2a";
          surface = "#2c2839";
          muted = "#4b455f";
          fg = "#9992b0";
          bright = "#efebff";
          s1 = "#8e8dbc";
          s2 = "#a69dff";
          s3 = "#b5acff";
          s4 = "#c4c0ff";
          s5 = "#d5d2ff";
          s6 = "#e5cbff";
          accent = "#b079ff";
        };

        mkLanguageModule = {
          format = "[  $symbol$version]($style)";
          style = "fg:${palette.bg} bg:${palette.s4}";
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
        cmd_duration = {
          show_notifications = false;
          min_time = 50;
          style = "fg:${palette.s6}";
        };

        nix_shell = {
          format = "[ $symbol$state( \\($name\\))]($style)";
          style = "fg:${palette.bg} bg:${palette.s4}";
        };

        os = {
          disabled = false;
          format = "[ $symbol]($style)";
          style = "fg:${palette.bright} bg:${palette.s1}";
        };

        username = {
          format = "[$user]($style)";
          style_user = "fg:${palette.bright} bg:${palette.s1}";
          style_root = "fg:${palette.accent} bg:${palette.s1}";
        };

        git_branch = {
          format = "[ $symbol$branch(:$remote_branch)]($style)";
          style = "fg:${palette.bg} bg:${palette.s4}";
        };

        git_status = {
          format = "[$all_status$ahead_behind]($style)";
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          behind = "⇣\${count}";
          stashed = "";
          style = "fg:${palette.bg} bg:${palette.s4}";
        };

        hostname = {
          ssh_only = true;
          format = "[@$hostname]($style)";
          style = "fg:${palette.bright} bg:${palette.s1}";
        };

        directory = {
          format = "[ $path]($style)";
          style = "fg:${palette.bg} bg:${palette.s2}";
        };

        time = {
          disabled = false;
          format = "[ $time]($style)";
          style = "fg:${palette.bg} bg:${palette.s6}";
        };

        format =
          let
            rightArrowSymbol = "";
            leftArrowSymbol = "";
            langs = "$elm$purescript$bun$deno$rust$golang$nodejs$haskell";

            sections = lib.strings.concatStrings [
              # s1: os / user / host (always visible)
              "[${leftArrowSymbol}](fg:${palette.s1})"
              "$os$username$hostname"
              "[${rightArrowSymbol}](bg:${palette.s2} fg:${palette.s1})"

              # s2: directory (always visible)
              "$directory"
              "[${rightArrowSymbol}](bg:${palette.s4} fg:${palette.s2})"

              # s4: git + languages + nix (all optional, shared bg)
              "$git_branch$git_status"
              "${langs}"
              "$nix_shell"
              "[${rightArrowSymbol}](fg:${palette.s4} bg:${palette.s6})"

              # s6: time (always visible)
              "$time"
              "[${rightArrowSymbol}](fg:${palette.s6})"

              " $cmd_duration"
            ];
          in
          ''
            ┌${sections}
            └─$character'';

        character = {
          success_symbol = "[λ](${palette.s5})";
          error_symbol = "[λ](${palette.accent})";
        };
      };
  };
}
