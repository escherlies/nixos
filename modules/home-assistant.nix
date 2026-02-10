{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;

    extraComponents = [
      "zha"
      "met"
      "isal"
    ];

    extraPackages =
      python3Packages: with python3Packages; [
        gtts
      ];

    config = {
      default_config = { };

      automation = "!include automations.yaml";

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
  networking.firewall.allowedTCPPorts = [ 8123 ]; # Fallback

  # Use reverse proxy with internal TLS issuer
  services.caddy.virtualHosts."${config.network.services.home-assistant.dns}".extraConfig = ''
    tls internal
    reverse_proxy 127.0.0.1:8123
  '';
}
