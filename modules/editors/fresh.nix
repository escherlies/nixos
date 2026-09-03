{ pkgs, inputs, ... }:

{
  environment.systemPackages = [ inputs.fresh.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  environment.variables.EDITOR = "fresh --no-restore";
}
