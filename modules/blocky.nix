{ config, lib, ... }:

let
  # Build LAN IP → VPN IP lookup table from machine definitions
  # This allows blocky to return both LAN and VPN IPs for each service,
  # enabling Happy Eyeballs: LAN clients connect directly, VPN clients
  # connect via their WireGuard tunnel.
  ipToVpnIp = builtins.listToAttrs (
    builtins.filter (pair: pair.value != null) (
      lib.mapAttrsToList (_name: m: lib.nameValuePair m.ipv4 m.vpnIp) config.machines
    )
  );
in
{
  imports = [ ./machines.nix ];

  services.blocky = {
    enable = true;
    settings = {
      # Upstream DNS configuration
      upstreams = {
        groups = {
          default = [
            # Mullvad DNS
            "https://dns.mullvad.net/dns-query"
            "tcp-tls:dns.mullvad.net:853"
            # DNS.SB
            "https://dns.sb/dns-query"
            "https://doh.dns.sb/dns-query"
            "tcp-tls:dot.sb:853"
            # Digitale Gesellschaft
            "https://dns.digitale-gesellschaft.ch/dns-query"
            "tcp-tls:dns.digitale-gesellschaft.ch:853"
            # JoinDNS4
            "https://protective.joindns4.eu/dns-query"
            "tcp-tls:protective.joindns4.eu:853"
            # Quad9
            "tcp-tls:dns.quad9.net:853"
            "https://dns.quad9.net/dns-query"
          ];
        };
        strategy = "parallel_best";
      };

      # Bootstrap DNS for resolving DoH/DoT hostnames
      bootstrapDns = [
        "tcp+udp:9.9.9.10"
        "tcp+udp:149.112.112.10"
        "tcp+udp:2620:fe::10"
        "tcp+udp:2620:fe::fe:10"
      ];

      # Custom DNS mappings — includes both LAN and VPN IPs so services
      # are reachable from both the home network and via WireGuard
      customDNS = {
        mapping = lib.mapAttrs' (
          _name: value:
          let
            vpnIp = ipToVpnIp.${value.ip} or null;
          in
          {
            name = value.dns;
            value = if vpnIp != null then "${value.ip},${vpnIp}" else value.ip;
          }
        ) config.network.services;
      };

      # Conditional DNS for local network
      conditional = {
        mapping = {
          "fritz.box" = "192.168.178.1";
        };
      };

      # Prometheus metrics
      prometheus = {
        enable = true;
        path = "/metrics";
      };

      # Ports config
      ports = {
        # optional: Port(s) and optional bind ip address(es) to serve HTTP used for prometheus metrics, pprof, REST API, DoH...
        # example: [4000, :4000, 127.0.0.1:4000, [::1]:4000]
        http = 4000;
      };
    };
  };

  # Open dns ports in firewall
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
}
