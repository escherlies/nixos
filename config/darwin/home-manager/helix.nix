{ pkgs, ... }:

{
  home.packages = [ pkgs.helix ];

  home.sessionVariables.EDITOR = "hx";
}
