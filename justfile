# Where a deployed machine gets the store paths it is missing.
#
#   no  (default) — this machine sends them over SSH.
#   yes           — the target substitutes what it can from cache.nixos.org
#                   itself, and only receives what is not there.
#
# "no" is the right default on the home LAN. Both closures are built from the
# same nixpkgs, so they overlap almost entirely and the delta is small; sending
# it at 34 MB/s beats making the target re-download paths this machine already
# holds. Set it to yes when the deploy is not the small case — a nixpkgs bump
# is ~2200 paths, nearly all already in the public cache — or when this machine
# is away from home and every path would climb a foreign uplink:
#
#   just substitute=yes rebuild-desktop
substitute := "no"

# The flake target is derived from the machine itself, so this recipe cannot
# activate another host's configuration.
# Rebuild the machine you are sitting at
rebuild:
    sudo nixos-rebuild switch --flake .#$(hostname)

# Deploy a machine's configuration to that machine over SSH.
#
# The guard exists because `nixos-rebuild --flake .#<host> --target-host <ip>`
# happily activates <host>'s configuration — hostname, hardware modules,
# bootloader — on whatever answers at that address. Addresses move: framework
# alone holds a different DHCP lease on ethernet than on WiFi, and .23 used to
# be a machine here. So ask the box what it is before handing it a system.
#
# Addresses are resolved by name via /etc/hosts (modules/hosts.nix), which is
# generated from modules/machines.nix — one registry, not a second copy here.
_deploy host action:
    #!/usr/bin/env bash
    set -euo pipefail
    # Checked before the network probe so a typo costs nothing. A misspelling
    # must not silently pick the slow half of the choice, hence no catch-all
    # that falls back to "no".
    case "{{ substitute }}" in
      yes) flags=(--use-substitutes); echo "paths: {{ host }} substitutes from cache.nixos.org" ;;
      no)  flags=();                  echo "paths: copying from $(hostname) over SSH" ;;
      *)   echo "substitute must be 'yes' or 'no', got '{{ substitute }}'" >&2; exit 2 ;;
    esac
    answered=$(ssh -o ConnectTimeout=5 -o BatchMode=yes root@{{ host }} hostname)
    if [ "$answered" != "{{ host }}" ]; then
      echo "refusing to deploy {{ host }}: root@{{ host }} answers as '$answered'" >&2
      exit 1
    fi
    nixos-rebuild {{ action }} --flake .#{{ host }} --target-host root@{{ host }} "${flags[@]}"

# Deploy laptop's configuration to laptop
rebuild-laptop: (_deploy "laptop" "switch")

# Deploy framework's configuration to framework
rebuild-framework: (_deploy "framework" "switch")

# Deploy desktop's configuration to desktop
rebuild-desktop: (_deploy "desktop" "switch")

# Stage desktop's configuration on desktop for the next boot
boot-desktop: (_deploy "desktop" "boot")

# Deploy home-server's configuration to home-server
rebuild-home-server: (_deploy "home-server" "switch")

# Deploy vpn-gateway's configuration to vpn-gateway
rebuild-vpn-gateway: (_deploy "vpn-gateway" "switch")
