{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.apps.brave;

  onEfficiencyCores = pkgs.callPackage ../../scripts/on-efficiency-cores.nix { };

  braveOnEfficiencyCores =
    pkgs.runCommand "brave-on-efficiency-cores"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        inherit (pkgs.brave) meta;
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${onEfficiencyCores}/bin/on-efficiency-cores $out/bin/brave \
          --add-flags ${pkgs.brave}/bin/brave

        # Everything but the launcher comes straight from upstream. Only the
        # desktop entries are rewritten: they name the unwrapped binary by
        # absolute store path, so a launch from GNOME would walk past the
        # wrapper and the confinement would appear to work only from a shell.
        mkdir -p $out/share
        for sharePath in ${pkgs.brave}/share/*; do
          shareName=$(basename "$sharePath")
          if [ "$shareName" != applications ]; then
            ln -s "$sharePath" "$out/share/$shareName"
          fi
        done

        mkdir -p $out/share/applications
        for desktopEntry in ${pkgs.brave}/share/applications/*.desktop; do
          substitute "$desktopEntry" "$out/share/applications/$(basename "$desktopEntry")" \
            --replace-fail "${pkgs.brave}/bin/brave" "$out/bin/brave"
        done
      '';
in
{
  options.apps.brave.confineToEfficiencyCores = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Launch Brave confined to the CPUs with the lower firmware frequency
      ceiling, so a saturated renderer thread cannot reach the boost cores.

      This is a thermal measure, not a throughput one. On `framework`
      (Ryzen AI 9 HX 370) one saturated browser main thread unconfined takes
      the die to 100 C and the fan to 5173 rpm; the same thread confined to
      the 3.29 GHz Zen5c cores runs at 76 C and 3574 rpm — which is the fan's
      idle speed — while frame rate and frame pacing are unchanged. It costs
      about 28% of raw JS throughput, which is the honest price.

      The benefit is largest exactly where browsers spend their time: one hot
      tab. Measured at three saturating threads it shrinks to 5.5 K, because
      both arms then sit on the same 25 W socket limit and an affinity mask
      caps clocks, not power. See docs/framework-thermal.md.

      On a CPU whose cores all share one firmware ceiling there is nothing to
      confine and Brave launches unchanged, so this is safe to leave on for
      every machine sharing this home configuration.

      `brave-unconfined` is always installed alongside, for the case where the
      throughput is worth the noise.
    '';
  };

  config = {
    home.packages = [
      onEfficiencyCores
      (if cfg.confineToEfficiencyCores then braveOnEfficiencyCores else pkgs.brave)
    ]
    ++ lib.optional cfg.confineToEfficiencyCores (
      pkgs.writeShellScriptBin "brave-unconfined" ''
        exec ${pkgs.brave}/bin/brave "$@"
      ''
    );

    programs.chromium.enable = true;

    programs.chromium.extensions = [
      { id = "gejiddohjgogedgjnonbofjigllpkmbf"; } # 1Password Nightly – Password Manager
    ];
  };
}
