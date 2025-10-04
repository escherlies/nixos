# Additional configurations for graphical systems
{ pkgs, ... }:
{
  imports = [
    ../modules/_1password.nix
    ../modules/fonts.nix
    ../modules/starship.nix

  ];

  environment.systemPackages = with pkgs; [
    ddcutil # https://wiki.nixos.org/wiki/Backlight#Via_ddcutil
  ];

  hardware.i2c.enable = true; # https://wiki.nixos.org/wiki/Backlight#Via_ddcutil
}
