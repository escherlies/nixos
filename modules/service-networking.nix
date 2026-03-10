{ lib, ... }:

let
  serviceOpts =
    { name, ... }:
    {
      options = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "The LAN IP address of the ${name} service.";
          example = "192.168.178.134";
        };
        dns = lib.mkOption {
          type = lib.types.str;
          description = "The LAN DNS name of the ${name} service (*.lan).";
          example = "service.lan";
        };
        wgDns = lib.mkOption {
          type = lib.types.str;
          description = "The WireGuard DNS name of the ${name} service (*.wg).";
          example = "service.wg";
        };
        machine = lib.mkOption {
          type = lib.types.str;
          description = "The machine name hosting the ${name} service (key in config.machines).";
          example = "home-server";
        };
      };
    };
in
{
  options.network.services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule serviceOpts);
    default = { };
    description = ''
      Internal networking configuration for services, including LAN IPs, DNS names,
      and WireGuard DNS names. VPN IPs are derived from the machine definition.
    '';
  };
}
