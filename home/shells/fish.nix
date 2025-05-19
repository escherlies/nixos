{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    functions = {
      fish_command_not_found = "echo Did not find command $argv[1]";

      # # Create and change to a directory
      mkdircd = ''mkdir -p -- "$1" && cd -- "$1"'';

      fish_greeting = "";
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

      # Other
      lsblk = "lsblk -o name,mountpoint,label,size,type,uuid";

      qr = "${pkgs.qrencode}/bin/qrencode -t utf8 -o-";

      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Berlin";

      zzz = "systemctl suspend";
    };
  };
}
