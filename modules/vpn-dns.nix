# VPN DNS — Blocky on vpn-gateway resolving *.wg names to WireGuard VPN IPs
#
# Runs on the gateway's WireGuard interface (10.100.0.1) so that VPN clients
# can resolve .wg service names to VPN IPs. All other queries are forwarded
# to upstream DNS resolvers.
{ config, lib, ... }:

let
  machines = config.machines;

  # Build customDNS mapping: wgDns -> machine's VPN IP
  wgMappings = lib.mapAttrs' (_name: svc: {
    name = svc.wgDns;
    value = machines.${svc.machine}.vpnIp;
  }) config.network.services;
in
{
  imports = [
    ./service-data.nix
  ];

  services.blocky = {
    enable = true;
    settings = {
      # Upstream DNS — forward non-.wg queries to privacy-focused resolvers
      upstreams = {
        groups = {
          default = [
            "https://dns.mullvad.net/dns-query"
            "tcp-tls:dns.mullvad.net:853"
            "https://dns.quad9.net/dns-query"
            "tcp-tls:dns.quad9.net:853"
          ];
        };
        strategy = "parallel_best";
      };

      # Bootstrap DNS for resolving DoH/DoT hostnames
      bootstrapDns = [
        "tcp+udp:9.9.9.10"
        "tcp+udp:149.112.112.10"
      ];

      # .wg domain mappings (VPN IPs)
      customDNS = {
        mapping = wgMappings;
      };

      # Listen only on the WireGuard interface
      ports = {
        dns = [
          "${machines.vpn-gateway.vpnIp}:53"
        ];
      };
    };
  };

  # Allow DNS traffic from VPN peers
  networking.firewall.interfaces.wg0 = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };
}
