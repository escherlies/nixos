# Packaged beside the script rather than inside one module, because two
# consumers need the same derivation: home/apps/brave.nix wraps Brave with it,
# and machines/framework/power.nix installs it system-wide and substitutes its
# path into core-type-bench.
{
  lib,
  writeShellScriptBin,
  util-linux,
}:

writeShellScriptBin "on-efficiency-cores" (
  lib.replaceStrings [ "exec taskset" ] [ "exec ${util-linux}/bin/taskset" ] (
    builtins.readFile ./on-efficiency-cores
  )
)
