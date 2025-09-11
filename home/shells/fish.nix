{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    functions = {
      __fish_command_not_found_handler = {
        body = "echo Did not find command $argv[1]";
        onEvent = "fish_command_not_found";
      };

      # # Create and change to a directory
      mkdircd = ''mkdir -p -- "$1" && cd -- "$1"'';

      fish_greeting = "";

      ai_commit =
        let
          prompt = builtins.readFile ../../config/commit.md;
        in
        ''git diff --staged | aichat -c ${builtins.toJSON prompt} | copy'';
    };

    shellAbbrs = {

      o = "open";
      q = "exit";
      v = "nvim";
    };

    shellAliases = rec {

      # Eza ls replacement
      ls = "${pkgs.eza}/bin/eza -1 --group-directories-first --icons";
      l = "${ls}";
      ll = "${ls} -lbF --git --color-scale";
      la = "${ls} -lbhgmua@ --color-scale --git";
      lt = "${ls} --tree --level=2";

      # Git
      gs = "${pkgs.git}/bin/git status";
      # git diff --no-ext-diff

      # Other
      lsblk = "lsblk -o name,mountpoint,label,size,type,uuid";

      qr = "${pkgs.qrencode}/bin/qrencode -t utf8 -o-";

      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Berlin";

      zzz = "systemctl suspend";

      copy = "wl-copy";

      nd = "nix develop -c $SHELL";
      day = "lookandfeeltool -a org.kde.breeze.desktop";
      night = "lookandfeeltool -a org.kde.breezedark.desktop";
    };
  };
}
