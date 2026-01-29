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

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };

    };
  };

  # Open firewall for Home Assistant
  networking.firewall.allowedTCPPorts = [ 8123 ];

}
