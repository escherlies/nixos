{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;

    extraComponents = [
      "zha"
      "met"
    ];

    config = {
      default_config = { };

      homeassistant = {
        unit_system = "metric";
        time_zone = "Europe/Berlin";
      };

    };
  };

  # Open firewall for Home Assistant
  networking.firewall.allowedTCPPorts = [ 8123 ];

}
