{ pkgs, inputs, ... }:

{
  environment.systemPackages = [ inputs.fresh.packages.${pkgs.system}.default ];

  environment.variables.EDITOR = "fresh --no-restore";
}
