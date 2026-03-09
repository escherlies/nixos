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
      vpnIp = "10.100.0.5";
    };
    iphone = {
      ipv4 = "0.0.0.0";
      vpnIp = "10.100.0.6";
    };
  };
}
