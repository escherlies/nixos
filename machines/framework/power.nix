# Thermal tooling for the Ryzen AI 9 HX 370 in this Framework 13.
#
# This file deliberately does NOT select a power profile. Forcing `power-saver`
# was tried and rejected: `platform_profile=low-power` drops the *firmware*
# ceiling to 2.0 GHz for every core on the machine, which is a 2.6x cut against
# `balanced` and is felt as stutter in ordinary desktop use. It trades the whole
# machine's responsiveness for a thermal problem that a single browser thread
# causes. See docs/framework-thermal.md.
#
# The heat is not a machine-wide setting. Measured with `core-type-bench` on
# this chassis, one saturated browser main thread on `balanced`:
#
#   arm                     socket W    die C       fan rpm     JS units/s
#   unconfined (Zen5)      20.4 / 25.0  99.8/100.1  4764/5173      4074
#   Zen5c cores only       12.7 / 23.1  76.1/ 79.4  3540/3574      2930
#
# Same one thread, same 1.15 cores of CPU time. The only difference is which
# cores it was allowed on, and it is worth 24 K and 1600 rpm — while frame rate
# and frame pacing were identical (119.5 vs 119.7 fps, p95 frame 8.4 ms both).
# The fix therefore belongs on the application, not on the machine, and lives
# in home/apps/brave.nix via `scripts/on-efficiency-cores`.
#
# The same A/B at three saturating threads gives only 5.5 K and 258 rpm: both
# arms hit the same 25.0 W socket ceiling, and once the part is power-limited
# the affinity mask has no excursion left to remove. An affinity mask is a
# clock cap, not a power cap — it pays off on tall, bursty load and not on wide
# load. docs/framework-thermal.md carries both tables.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  fromRepoScript =
    name: substitutions:
    pkgs.writeShellScriptBin name (
      lib.replaceStrings (builtins.attrNames substitutions) (builtins.attrValues substitutions) (
        builtins.readFile (../../scripts + "/${name}")
      )
    );

  onEfficiencyCores = pkgs.callPackage ../../scripts/on-efficiency-cores.nix { };
in
{
  # The harnesses that produced the numbers above and in
  # docs/framework-thermal.md, so they can be re-derived on this machine after
  # a BIOS, kernel or nixpkgs bump rather than trusted from a comment. The
  # ceilings that all of this rests on are set by firmware, which is exactly
  # the kind of thing a BIOS update moves without announcing it.
  environment.systemPackages = [
    onEfficiencyCores
    (fromRepoScript "power-bench" {
      "powerprofilesctl" = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";
    })
    (fromRepoScript "core-type-bench" {
      "taskset -a -cp" = "${pkgs.util-linux}/bin/taskset -a -cp";
      "curl -s" = "${pkgs.curl}/bin/curl -s";
      "jq -r" = "${pkgs.jq}/bin/jq -r";
      # Resolved rather than taken from PATH: this harness is the thing that
      # decides which cores the Brave wrapper will use, so both must agree on
      # one derivation.
      "on-efficiency-cores --list" = "${onEfficiencyCores}/bin/on-efficiency-cores --list";
    })
  ];
}
