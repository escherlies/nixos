{ config, lib, ... }:

let
  cfg = config.vpn;

  # VPN subnet: 10.100.0.0/24
  # Hub: vpn-gateway (10.100.0.1) — the only peer with a public endpoint
  # Clients: all other machines connect through the hub

  peers = {
    vpn-gateway = {
      vpnIp = "10.100.0.1";
      publicKey = "2P4CMhjiEypHv8f4UwJX9GoWQsHnkFZORk84I4QyUgU=";
      endpoint = "65.21.50.151:51820";
    };
    home-server = {
      vpnIp = "10.100.0.2";
      publicKey = "nVuBDhrjE5z9dAnUk2xSed/cj65fpWy8+dVT6si0VQ0=";
      endpoint = null;
    };
    desktop = {
      vpnIp = "10.100.0.3";
      publicKey = "cDAuFVQa4/mlLfMG9b2JlODASes35iAipBHYhrwQVQY=";
      endpoint = null;
    };
    framework = {
      vpnIp = "10.100.0.4";
      publicKey = "6K6x1hAMrLPBNrbO+d/87a1aXAJZLpgG+EeiJnyue08=";
      endpoint = null;
    };
    laptop = {
      vpnIp = "10.100.0.5";
      publicKey = "KgQvkZitebxibx+iyPAhYAfX3rV9ZBtLcpupCOXq21A=";
      endpoint = null;
    };
  };

  hostname = config.networking.hostName;
  thisPeer = peers.${hostname};
  isHub = hostname == "vpn-gateway";

  # Hub peer config: list all clients as peers with their /32 VPN IPs
  hubPeers = lib.mapAttrsToList (
    name: peer: {
      inherit (peer) publicKey;
      allowedIPs = [ "${peer.vpnIp}/32" ];
    }
  ) (lib.filterAttrs (name: _: name != hostname) peers);

  # Client peer config: only the hub as a peer, route all VPN traffic through it
  clientPeers = [
    {
      publicKey = peers.vpn-gateway.publicKey;
      endpoint = peers.vpn-gateway.endpoint;
      allowedIPs = [ "10.100.0.0/24" ];
      persistentKeepalive = 25;
    }
  ];

in
{
  options.vpn.enable = lib.mkEnableOption "WireGuard VPN";

  config = lib.mkIf cfg.enable {
    # Decrypt this machine's WireGuard private key via agenix
    age.secrets."wg-${hostname}" = {
      file = ../secrets/wg-${hostname}.key.age;
      mode = "0400";
    };

    networking.wireguard.interfaces.wg0 = {
      ips = [ "${thisPeer.vpnIp}/24" ];
      listenPort = if isHub then 51820 else null;
      privateKeyFile = config.age.secrets."wg-${hostname}".path;
      peers = if isHub then hubPeers else clientPeers;
    };

    networking.firewall = {
      # Allow WireGuard traffic on the hub
      allowedUDPPorts = lib.mkIf isHub [ 51820 ];
      # Required for WireGuard
      checkReversePath = "loose";
    };

    # Hub needs to forward packets between peers
    boot.kernel.sysctl = lib.mkIf isHub {
      "net.ipv4.ip_forward" = 1;
    };
  };
}
