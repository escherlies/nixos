# Thermal tuning for the Framework 13 (Ryzen AI 9 HX 370, 12C/24T).
#
# The entire cooling budget on this chassis is one heatpipe and one fan on the
# mainboard, so what decides how hot and how loud this machine gets is the
# SoC's *boost ceiling* — not the governor, and not which services are
# resident. Measured on this machine on 2026-08-14 (kernel 6.18.39), sampling
# k10temp / amdgpu socket power / cros_ec fan RPM at 1 Hz, with an identical
# 24-thread busy load held for 75 s:
#
#                  idle (150 s)          all-core load (75 s)
#   profile      temp    SoC   fan     temp max   SoC    fan    avg clk
#   power-saver  50.3 C  3.9 W  0 rpm   67.1 C   20.1 W  4183   1574 MHz
#   balanced     53.2 C  4.3 W  0 rpm   88.0 C   37.0 W  6182   2364 MHz
#   performance  58.6 C  5.9 W  0 rpm   93.4 C   38.0 W  6221   2516 MHz
#
# `balanced` lifts scaling_max_freq from 2.0 GHz to 5.16 GHz. That is the whole
# difference against power-saver: +21 C, +17 W and +2000 rpm of fan under load,
# bought with +50 % average clock. A real trade, sometimes worth taking.
#
# `performance` is not. It shares balanced's 5.16 GHz ceiling and changes only
# the governor and EPP (both to `performance`), and on this chassis that buys
# **+6.4 % average clock for +6 C, +4 W and ~1000 rpm more fan**. The single
# heatpipe is already saturated at balanced, so the extra power leaves as heat
# and noise rather than as work. It also costs 8 C and 50 % more SoC power at
# *idle* — 58.6 C / 5.9 W against 50.3 C / 3.9 W — for doing nothing at all.
# There is no measured case for using it on this machine.
#
# The subtlety that shapes the fix: under a genuine all-core load the SoC is
# power-limited to ~2364 MHz average anyway, so the top of that 5.16 GHz range
# buys almost no multi-threaded throughput. It is nevertheless reached
# constantly by short single-core desktop work — at *idle* on `balanced`,
# cores were observed touching 4111 MHz with 13.0 W / 60.1 C excursions, versus
# 2022 MHz / 6.0 W / 51.2 C on power-saver under the same desktop load. Those
# transients are what produce the audible fan surges during ordinary use.
#
# So: keep `balanced`'s higher sustained power ceiling for when real work needs
# it, but cap the clock ceiling that the transients chase.
#
# The cap is applied *only* while the ACPI platform profile is `balanced`.
# `power-saver` already clamps harder on its own, and `performance` is left
# completely untouched so that deliberately asking for full speed still gives
# full speed.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.thermal;

  platformProfilePath = "/sys/firmware/acpi/platform_profile";

  applyBoostCeiling = pkgs.writeShellScript "framework-apply-boost-ceiling" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}

    if [ ! -r "${platformProfilePath}" ]; then
      echo "framework-boost-ceiling: ${platformProfilePath} is missing — the ACPI" \
           "platform-profile driver is not loaded, so this machine is not in the" \
           "state this module was written for." >&2
      exit 1
    fi

    shopt -s nullglob
    cpufreqPolicies=(/sys/devices/system/cpu/cpufreq/policy*)
    if [ ''${#cpufreqPolicies[@]} -eq 0 ]; then
      echo "framework-boost-ceiling: no cpufreq policies found — amd-pstate is not" \
           "active. Refusing to silently do nothing." >&2
      exit 1
    fi

    activeProfile=$(cat "${platformProfilePath}")

    for policyDirectory in "''${cpufreqPolicies[@]}"; do
      firmwareCeilingKHz=$(cat "$policyDirectory/cpuinfo_max_freq")

      if [ "$activeProfile" = "balanced" ]; then
        targetCeilingKHz=${toString cfg.boostCeilingKHz}
        # Never raise the ceiling above what the firmware currently permits.
        if [ "$targetCeilingKHz" -gt "$firmwareCeilingKHz" ]; then
          targetCeilingKHz=$firmwareCeilingKHz
        fi
      else
        # Not our profile to manage — hand the ceiling back to the firmware.
        targetCeilingKHz=$firmwareCeilingKHz
      fi

      echo "$targetCeilingKHz" > "$policyDirectory/scaling_max_freq"
    done
  '';
in
{
  options.modules.thermal = {
    limitBoostCeiling = lib.mkEnableOption ''
      capping the AMD P-State clock ceiling while the ACPI platform profile is
      `balanced`, to suppress the short single-core boost transients that drive
      fan surges on the Framework 13's single-heatpipe cooler
    '';

    boostCeilingKHz = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3200000;
      example = 2800000;
      description = ''
        Maximum CPU frequency in kHz to allow while the platform profile is
        `balanced`.

        The default of 3.2 GHz sits deliberately between `power-saver`'s
        2.0 GHz clamp and the 5.16 GHz firmware ceiling: it keeps 1.6x
        power-saver's interactive headroom while staying below the part of the
        voltage/frequency curve where power rises far faster than performance.
        Measured all-core load already averages ~2.4 GHz because it is
        power-limited, so this cap costs very little sustained throughput.

        Lower it toward 2.8 GHz for a quieter machine, raise it for more
        single-threaded speed, and re-measure rather than guessing.
      '';
    };
  };

  config = lib.mkIf cfg.limitBoostCeiling {
    systemd.services.framework-boost-ceiling = {
      description = "Cap AMD P-State clock ceiling on the balanced platform profile";
      wantedBy = [ "multi-user.target" ];
      after = [ "power-profiles-daemon.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = applyBoostCeiling;
      };
    };

    # power-profiles-daemon changes the ACPI platform profile at runtime, and
    # amd-pstate recomputes scaling_max_freq from firmware when it does — which
    # silently drops the cap. sysfs attributes do not deliver inotify events,
    # so there is nothing to subscribe to; re-asserting on a short timer is the
    # honest mechanism. The work is ~24 sysfs writes, so the cost is noise.
    systemd.timers.framework-boost-ceiling = {
      description = "Re-assert the AMD P-State clock ceiling after profile changes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
        AccuracySec = "10s";
      };
    };
  };
}
