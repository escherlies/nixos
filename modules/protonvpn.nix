{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.protonvpn;

  # Extract the IP from endpoint "IP:port" for routing exceptions
  endpointIp = builtins.head (lib.splitString ":" cfg.peer.endpoint);
in
{
  options.protonvpn = {
    enable = lib.mkEnableOption "ProtonVPN WireGuard gateway for LAN traffic";

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the ProtonVPN WireGuard private key file (agenix secret)";
    };

    address = lib.mkOption {
      type = lib.types.str;
      description = "WireGuard address assigned by ProtonVPN (e.g. 10.2.0.2/32)";
      example = "10.2.0.2/32";
    };

    peer = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "ProtonVPN server's WireGuard public key";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        description = "ProtonVPN server endpoint (IP:port)";
        example = "185.159.158.1:51820";
      };
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "eno1";
      description = "LAN network interface to NAT through ProtonVPN";
    };

    lanSubnet = lib.mkOption {
      type = lib.types.str;
      default = "192.168.178.0/24";
      description = "LAN subnet that should be routed through ProtonVPN";
    };

    vpnMeshSubnet = lib.mkOption {
      type = lib.types.str;
      default = "10.100.0.0/24";
      description = "WireGuard mesh VPN subnet to exclude from ProtonVPN routing";
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "DNS servers provided by ProtonVPN (leave empty to keep using blocky)";
    };

    killSwitch = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Block LAN internet traffic if ProtonVPN tunnel goes down";
    };

    routingTable = lib.mkOption {
      type = lib.types.int;
      default = 51820;
      description = "Custom routing table number for ProtonVPN policy routing";
    };

    fwmark = lib.mkOption {
      type = lib.types.int;
      default = 51820;
      description = "Firewall mark for ProtonVPN routing policy";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable IP forwarding for gateway functionality
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };

    # ProtonVPN WireGuard interface (separate from the mesh wg0)
    networking.wg-quick.interfaces.protonvpn0 = {
      privateKeyFile = cfg.privateKeyFile;
      address = [ cfg.address ];
      mtu = 1420;

      # table = "off" — we handle routing ourselves via policy routing
      # to avoid conflicting with the wg0 mesh default route
      table = "off";

      peers = [
        {
          publicKey = cfg.peer.publicKey;
          endpoint = cfg.peer.endpoint;
          allowedIPs = [ "0.0.0.0/0" ];
          persistentKeepalive = 25;
        }
      ];

      # Policy routing setup:
      #
      # The goal is to route both LAN-forwarded traffic AND the home-server's
      # own outbound traffic through ProtonVPN, while preserving:
      #   - WireGuard mesh (wg0) on 10.100.0.0/24
      #   - LAN-local traffic on 192.168.178.0/24
      #   - The ProtonVPN endpoint itself (must reach it via normal route)
      #
      # We use fwmark + policy routing to achieve this without touching the
      # main routing table.
      postUp =
        let
          ip = "${pkgs.iproute2}/bin/ip";
          ipt = "${pkgs.iptables}/bin/iptables";
          mark = toString cfg.fwmark;
          table = toString cfg.routingTable;
        in
        ''
          # --- Routing table ---
          # Default route via ProtonVPN in custom table
          ${ip} route add default dev protonvpn0 table ${table}

          # Policy: packets with our fwmark use the ProtonVPN table
          ${ip} rule add fwmark ${mark} table ${table} priority 100

          # --- Mark forwarded LAN traffic ---
          # Packets arriving from LAN, destined for the internet (not LAN or VPN mesh)
          ${ipt} -t mangle -A PREROUTING \
            -i ${cfg.lanInterface} \
            ! -d ${cfg.lanSubnet} \
            ! -d ${cfg.vpnMeshSubnet} \
            -j MARK --set-mark ${mark}

          # --- Mark home-server's own outbound traffic ---
          # Exclude: LAN, VPN mesh, ProtonVPN endpoint (avoid routing loop),
          # and loopback destinations
          ${ipt} -t mangle -A OUTPUT \
            ! -d ${cfg.lanSubnet} \
            ! -d ${cfg.vpnMeshSubnet} \
            ! -d ${endpointIp}/32 \
            ! -d 127.0.0.0/8 \
            ! -o wg0 \
            ! -o lo \
            -j MARK --set-mark ${mark}

          # --- NAT ---
          # Masquerade all traffic leaving via ProtonVPN
          ${ipt} -t nat -A POSTROUTING -o protonvpn0 -j MASQUERADE

          ${lib.optionalString cfg.killSwitch ''
            # --- Kill switch ---
            # Drop forwarded LAN traffic that would bypass ProtonVPN
            ${ipt} -I FORWARD \
              -i ${cfg.lanInterface} \
              ! -o protonvpn0 \
              ! -d ${cfg.lanSubnet} \
              ! -d ${cfg.vpnMeshSubnet} \
              -j DROP
          ''}
        '';

      postDown =
        let
          ip = "${pkgs.iproute2}/bin/ip";
          ipt = "${pkgs.iptables}/bin/iptables";
          mark = toString cfg.fwmark;
          table = toString cfg.routingTable;
        in
        ''
          # Clean up routing
          ${ip} rule del fwmark ${mark} table ${table} priority 100 || true
          ${ip} route del default dev protonvpn0 table ${table} || true

          # Clean up mangle marks
          ${ipt} -t mangle -D PREROUTING \
            -i ${cfg.lanInterface} \
            ! -d ${cfg.lanSubnet} \
            ! -d ${cfg.vpnMeshSubnet} \
            -j MARK --set-mark ${mark} || true

          ${ipt} -t mangle -D OUTPUT \
            ! -d ${cfg.lanSubnet} \
            ! -d ${cfg.vpnMeshSubnet} \
            ! -d ${endpointIp}/32 \
            ! -d 127.0.0.0/8 \
            ! -o wg0 \
            ! -o lo \
            -j MARK --set-mark ${mark} || true

          # Clean up NAT
          ${ipt} -t nat -D POSTROUTING -o protonvpn0 -j MASQUERADE || true

          ${lib.optionalString cfg.killSwitch ''
            ${ipt} -D FORWARD \
              -i ${cfg.lanInterface} \
              ! -o protonvpn0 \
              ! -d ${cfg.lanSubnet} \
              ! -d ${cfg.vpnMeshSubnet} \
              -j DROP || true
          ''}
        '';
    };

    # Loosen reverse path check — required when multiple WireGuard interfaces
    # and policy routing are in play
    networking.firewall.checkReversePath = "loose";

    # Ensure iptables is available
    environment.systemPackages = [ pkgs.iptables ];
  };
}
