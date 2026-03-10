{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.vpn;
  machines = config.machines;

  # Two VPN networks:
  #   wg0  — trusted   (10.100.0.0/24) — full mesh via hub, peers can reach each other
  #   wg1  — untrusted (10.100.1.0/24) — isolated, only reachable via hub (e.g. ssh -J)
  #
  # Hub: vpn-gateway — has an interface on each network
  # Clients: connect to the hub on their respective network

  # WireGuard public keys (per machine)
  peerKeys = {
    vpn-gateway = {
      publicKey = "2P4CMhjiEypHv8f4UwJX9GoWQsHnkFZORk84I4QyUgU=";
    };
    vpn-gateway-untrusted = {
      publicKey = "QQvTZdQJKgeqCXxnL3exKEDl8UDXkzO537YtexkfDSc=";
    };
    home-server = {
      publicKey = "nVuBDhrjE5z9dAnUk2xSed/cj65fpWy8+dVT6si0VQ0=";
    };
    desktop = {
      publicKey = "cDAuFVQa4/mlLfMG9b2JlODASes35iAipBHYhrwQVQY=";
    };
    framework = {
      publicKey = "6K6x1hAMrLPBNrbO+d/87a1aXAJZLpgG+EeiJnyue08=";
    };
    laptop = {
      publicKey = "KgQvkZitebxibx+iyPAhYAfX3rV9ZBtLcpupCOXq21A=";
    };
    iphone = {
      publicKey = "+miJXGV74c6U7uPAUt4+WBmL8xBiv/R1GVIbjJbsUUU=";
    };
  };

  hostname = config.networking.hostName;
  isHub = hostname == "vpn-gateway";
  thisMachine = machines.${hostname};
  isTrusted = thisMachine.vpnNetwork == "trusted";

  # Machines that don't run their own DNS resolver need systemd-resolved
  # to route .lan queries to blocky via the VPN tunnel.
  # Untrusted machines can't reach blocky, so they don't get DNS routing.
  needsDnsRouting = !isHub && isTrusted && !config.services.blocky.enable;

  # Hub port assignments
  trustedPort = 51820;
  untrustedPort = 51821;

  # --- Hub peer lists ---

  # Peers on each network (excluding the hub itself)
  trustedPeerNames = lib.filter (n: n != "vpn-gateway") (
    lib.attrNames (lib.filterAttrs (_: m: m.vpnNetwork == "trusted" && m.vpnIp != null) machines)
  );
  untrustedPeerNames = lib.attrNames (
    lib.filterAttrs (_: m: m.vpnNetwork == "untrusted" && m.vpnIp != null) machines
  );

  mkHubPeers =
    names:
    map (name: {
      publicKey = peerKeys.${name}.publicKey;
      allowedIPs = [ "${machines.${name}.vpnIp}/32" ];
    }) names;

  # --- Client peer config ---

  # Trusted clients peer with the hub's wg0 key on the trusted port
  trustedClientPeers = [
    {
      publicKey = peerKeys.vpn-gateway.publicKey;
      endpoint = "${machines.vpn-gateway.ipv4}:${toString trustedPort}";
      allowedIPs = [ "10.100.0.0/24" ];
      persistentKeepalive = 25;
    }
  ];

  # Untrusted clients peer with the hub's wg1 key on the untrusted port
  untrustedClientPeers = [
    {
      publicKey = peerKeys.vpn-gateway-untrusted.publicKey;
      endpoint = "${machines.vpn-gateway.ipv4}:${toString untrustedPort}";
      allowedIPs = [ "10.100.1.0/24" ];
      persistentKeepalive = 25;
    }
  ];

in
{
  imports = [ ./machines.nix ];

  options.vpn.enable = lib.mkEnableOption "WireGuard VPN";

  config = lib.mkIf cfg.enable {
    # Decrypt this machine's WireGuard private key via agenix
    age.secrets."wg-${hostname}" = {
      file = ../secrets/wg-${hostname}.key.age;
      mode = "0400";
    };

    # Hub needs a second key for the untrusted network (wg1)
    age.secrets."wg-${hostname}-untrusted" = lib.mkIf isHub {
      file = ../secrets/wg-${hostname}-untrusted.key.age;
      mode = "0400";
    };

    # Enable systemd-resolved on trusted VPN clients for split DNS routing.
    # This lets .lan queries go to blocky (on the home-server) via WireGuard,
    # while all other DNS queries use the default resolver.
    services.resolved.enable = lib.mkIf needsDnsRouting true;

    networking.wireguard.interfaces = lib.mkMerge [

      # --- wg0: trusted network (all machines except untrusted clients) ---
      (lib.mkIf (isHub || isTrusted) {
        wg0 = {
          ips = [
            (if isHub then "10.100.0.1/24" else "${thisMachine.vpnIp}/24")
          ];
          listenPort = lib.mkIf isHub trustedPort;
          privateKeyFile = config.age.secrets."wg-${hostname}".path;
          peers = if isHub then mkHubPeers trustedPeerNames else trustedClientPeers;

          # Configure split DNS: route .lan queries to blocky via VPN
          postSetup = lib.mkIf needsDnsRouting ''
            ${pkgs.systemd}/bin/resolvectl dns wg0 ${machines.home-server.vpnIp}
            ${pkgs.systemd}/bin/resolvectl domain wg0 "~lan"
          '';
          postShutdown = lib.mkIf needsDnsRouting ''
            ${pkgs.systemd}/bin/resolvectl revert wg0 || true
          '';
        };
      })

      # --- wg1: untrusted network (hub + untrusted clients) ---
      # On the hub: second interface with its own keypair
      (lib.mkIf isHub {
        wg1 = {
          ips = [ "10.100.1.1/24" ];
          listenPort = untrustedPort;
          privateKeyFile = config.age.secrets."wg-${hostname}-untrusted".path;
          peers = mkHubPeers untrustedPeerNames;
        };
      })

      # On untrusted clients: wg1 connects to the hub's wg1
      (lib.mkIf (!isHub && !isTrusted) {
        wg1 = {
          ips = [ "${thisMachine.vpnIp}/24" ];
          privateKeyFile = config.age.secrets."wg-${hostname}".path;
          peers = untrustedClientPeers;
        };
      })
    ];

    networking.firewall = {
      # Allow WireGuard traffic on the hub (both ports)
      allowedUDPPorts = lib.mkIf isHub [
        trustedPort
        untrustedPort
      ];
      # Required for WireGuard
      checkReversePath = "loose";
    };

    # Hub needs to forward packets between trusted peers (wg0 only).
    # No forwarding between wg0 and wg1 — the untrusted network is isolated.
    boot.kernel.sysctl = lib.mkIf isHub {
      "net.ipv4.ip_forward" = 1;
    };
  };
}
