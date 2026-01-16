{ lib, ... }:

{
  options.server.metadata = {
    ipv4 = lib.mkOption {
      type = lib.types.str;
      description = "IPv4 address of the server for deployment scripts";
      example = "192.168.1.100";
    };
  };
}
