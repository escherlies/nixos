{ pkgs, ... }:
{
  fonts = {
    fontDir.enable = true; # Needed for some programs to find them
    fontconfig.enable = true;
    packages = with pkgs; [
      inter
      fira-code
      nerd-fonts.space-mono
    ];
  };
}
