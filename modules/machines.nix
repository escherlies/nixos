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
        };
      }
    );
    description = "Centralized machine IP definitions";
    default = { };
  };

  config.machines = {
    home-server = {
      ipv4 = "192.168.178.134";
    };
    desktop = {
      ipv4 = "192.168.178.87";
    };
  };
}
