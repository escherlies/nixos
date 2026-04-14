{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.helix ];

  environment.variables.EDITOR = "hx";
}
