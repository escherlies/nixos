{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.micro ];

  environment.variables.EDITOR = "micro";
}
