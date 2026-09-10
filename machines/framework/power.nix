# Boot this machine into the power profile its thermals were measured for.
#
# power-profiles-daemon persists the last selected profile in
# /var/lib/power-profiles-daemon/state.ini and restores it at boot. Nothing
# ever puts it back, so one burst to `balanced` for a build becomes the
# machine's permanent setting — which is exactly the state this file was
# written to end.
#
# Measured on this chassis with `scripts/power-bench` (24-thread load, 1 Hz
# sampling of `amdgpu/power1_average`, `k10temp/temp1_input`, `fan1_input`),
# 2026-09-10 on kernel 6.18.48. Averages / maxima:
#
#   profile      phase   socket power    die temp      fan        clock
#   power-saver  idle     5.4 /  8.0 W  61.9 / 64.8 C  3328 rpm   / 2018 MHz
#   power-saver  load    14.6 / 15.0 W  68.2 / 69.6 C  3769 rpm   / 2015 MHz
#   balanced     idle     9.5 / 26.1 W  67.9 / 84.6 C  3228 rpm   / 5077 MHz
#   balanced     load    27.0 / 33.0 W  83.0 / 85.4 C  4989 rpm   / 3583 MHz
#   performance  idle    12.5 / 24.0 W  67.9 / 76.5 C  3803 rpm   / 5181 MHz
#   performance  load    35.3 / 48.1 W  92.0 / 96.0 C  5686 rpm   / 3951 MHz
#
# The idle rows are why this file exists. On `balanced` an idle desktop still
# spikes to 5077 MHz, 26.1 W and 84.6 C, because every ordinary wakeup is free
# to chase the 5.16 GHz ceiling; on `power-saver` the firmware ceiling is
# 2.0 GHz and the same session never exceeds 8.0 W or 64.8 C. Those transients,
# not sustained work, are what make the fan audible during normal use.
#
# `performance` is never the right choice here: it costs 8.3 W and 9 K more
# than `balanced` under load for 326 MHz, because the single heatpipe is
# already saturated. See docs/framework-thermal.md for the full method and for
# the negative result that rules out a `scaling_max_freq` middle point — in
# amd-pstate active mode the firmware ceiling is the only real lever, and
# `platform_profile` is what moves it.
#
# This selects the profile the machine *starts* in, not one it is pinned to.
# GNOME's quick-settings menu still switches it at runtime, which is the point:
# burst to `balanced` when the work justifies it, and the next boot comes back
# cool instead of inheriting the burst.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.power;
in
{
  options.power.bootProfile = lib.mkOption {
    type = lib.types.enum [
      "power-saver"
      "balanced"
      "performance"
    ];
    default = "power-saver";
    description = ''
      The power-profiles-daemon profile to select on every boot, overriding
      whatever profile the previous session happened to leave behind.
    '';
  };

  config = {
    # Without power-profiles-daemon there is no profile to select and the unit
    # below would fail on every boot with a D-Bus error rather than saying why.
    assertions = [
      {
        assertion = config.services.power-profiles-daemon.enable;
        message = ''
          power.bootProfile is set to "${cfg.bootProfile}" but
          services.power-profiles-daemon.enable is false, so there is no daemon
          to select a profile on. Either enable it (the GNOME module does) or
          remove the import of machines/framework/power.nix.
        '';
      }
    ];

    systemd.services.boot-power-profile = {
      description = "Select the boot-default power profile (${cfg.bootProfile})";
      wantedBy = [ "multi-user.target" ];
      after = [ "power-profiles-daemon.service" ];
      requires = [ "power-profiles-daemon.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl set ${cfg.bootProfile}";
      };
    };

    # The benchmark that produced the table above, so the numbers can be
    # re-derived on this machine after a BIOS, kernel or nixpkgs bump rather
    # than trusted from a comment.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "power-bench" (
        lib.replaceStrings [ "powerprofilesctl" ] [
          "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl"
        ] (builtins.readFile ../../scripts/power-bench)
      ))
    ];
  };
}
