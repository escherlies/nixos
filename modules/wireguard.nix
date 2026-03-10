{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.vpn;
  machines = config.machines;

  # VPN subnet: 10.100.0.0/24
  # Hub: vpn-gateway (10.100.0.1) — the only peer with a public endpoint
  # Clients: all other machines connect through the hub

  # WireGuard-specific peer config (public keys and endpoints only)
  # VPN IPs are defined centrally in modules/machines.nix
  peerKeys = {
    vpn-gateway = {
      publicKey = "2P4CMhjiEypHv8f4UwJX9GoWQsHnkFZORk84I4QyUgU=";
      endpoint = "${machines.vpn-gateway.ipv4}:51820";
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

  # Machines that don't run their own DNS resolver need systemd-resolved
  # to route .lan queries to blocky via the VPN tunnel
  needsDnsRouting = !isHub && !config.services.blocky.enable;

  # Hub peer config: list all clients as peers with their /32 VPN IPs
  hubPeers = lib.mapAttrsToList (name: keys: {
    inherit (keys) publicKey;
    allowedIPs = [ "${machines.${name}.vpnIp}/32" ];
  }) (lib.filterAttrs (name: _: name != hostname) peerKeys);

  # Client peer config: only the hub as a peer, route all VPN traffic through it
  clientPeers = [
    {
      publicKey = peerKeys.vpn-gateway.publicKey;
      endpoint = peerKeys.vpn-gateway.endpoint;
      allowedIPs = [ "10.100.0.0/24" ];
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

    # Enable systemd-resolved on VPN clients for split DNS routing.
    # This lets .lan queries go to blocky (on the home-server) via WireGuard,
    # while all other DNS queries use the default resolver.
    services.resolved.enable = lib.mkIf needsDnsRouting true;

    networking.wireguard.interfaces.wg0 = {
      ips = [ "${machines.${hostname}.vpnIp}/24" ];
      listenPort = lib.mkIf isHub 51820;
      privateKeyFile = config.age.secrets."wg-${hostname}".path;
      peers = if isHub then hubPeers else clientPeers;

      # Configure split DNS: route .lan queries to blocky via VPN
      postSetup = lib.mkIf needsDnsRouting ''
        ${pkgs.systemd}/bin/resolvectl dns wg0 ${machines.home-server.vpnIp}
        ${pkgs.systemd}/bin/resolvectl domain wg0 "~lan"
      '';
      postShutdown = lib.mkIf needsDnsRouting ''
        ${pkgs.systemd}/bin/resolvectl revert wg0 || true
      '';
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
