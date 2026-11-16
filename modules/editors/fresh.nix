{ pkgs, inputs, ... }:

let
  # fresh asks "Trust folder?" for every project folder that contains
  # Cargo.toml, package.json, .envrc and similar markers. The patch makes
  # every undecided folder Trusted, so the prompt never opens. It targets
  # the commit pinned in flake.nix; re-check it when that pin moves.
  fresh = inputs.fresh.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/fresh-trust-all-folders.patch ];
  });
in
{
  environment.systemPackages = [ fresh ];

  environment.variables.EDITOR = "fresh --no-restore";
}
