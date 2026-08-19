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
    answered=$(ssh -o ConnectTimeout=5 -o BatchMode=yes root@{{ host }} hostname)
    if [ "$answered" != "{{ host }}" ]; then
      echo "refusing to deploy {{ host }}: root@{{ host }} answers as '$answered'" >&2
      exit 1
    fi
    nixos-rebuild {{ action }} --flake .#{{ host }} --target-host root@{{ host }}

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
