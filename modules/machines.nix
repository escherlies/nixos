{ lib, ... }:

{
  options.machines = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address of the machine";
          };
          vpnIp = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "WireGuard VPN IP address of the machine";
            default = null;
          };
          vpnNetwork = lib.mkOption {
            type = lib.types.enum [
              "trusted"
              "untrusted"
            ];
            description = ''
              Which VPN network the machine belongs to.
              Trusted machines share wg0 (10.100.0.0/24) and can reach each other.
              Untrusted machines are isolated on wg1 (10.100.1.0/24) and can only
              be reached via the hub (e.g. ssh -J vpn-gateway).
            '';
            default = "trusted";
          };
        };
      }
    );
    description = "Centralized machine IP definitions";
    default = { };
  };

  config.machines = {
    vpn-gateway = {
      ipv4 = "65.21.50.151";
      vpnIp = "10.100.0.1";
    };
    home-server = {
      ipv4 = "192.168.178.134";
      vpnIp = "10.100.0.2";
    };
    desktop = {
      ipv4 = "192.168.178.87";
      vpnIp = "10.100.0.3";
    };
    framework = {
      ipv4 = "192.168.178.23";
      vpnIp = "10.100.0.4";
    };
    laptop = {
      ipv4 = "192.168.178.98";
      vpnIp = "10.100.1.2";
      vpnNetwork = "untrusted";
    };
    iphone = {
      ipv4 = "0.0.0.0";
      vpnIp = "10.100.0.6";
    };
  };
}
