{ lib, ... }:

let
  serviceOpts =
    { name, ... }:
    {
      options = {
        ip = lib.mkOption {
          type = lib.types.str;
          description = "The internal IP address of the ${name} service.";
          example = "10.0.0.1";
        };
        dns = lib.mkOption {
          type = lib.types.str;
          description = "The DNS name/hostname of the ${name} service.";
          example = "service.local";
        };
      };
    };
in
{
  options.network.services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule serviceOpts);
    default = { };
    description = ''
      Internal networking configuration for services, including IPs and DNS names.
      This allows centralizing service addresses and referencing them across the configuration.
    '';
  };
}
