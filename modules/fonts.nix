{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true; # Needed for some programs to find them
    fontconfig.enable = true;
    packages = with pkgs; [

      inter
      aporetic
      iosevka
      ibm-plex

      # 🤓 Nerd Fonts
      nerd-fonts.fira-code
      nerd-fonts.space-mono
      nerd-fonts.monaspace
      nerd-fonts.hack
      nerd-fonts._0xproto
    ];
  };
}
