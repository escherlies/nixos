{ config, pkgs, lib, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.hostName = "nixos-monitoring";
  security.acme.defaults.email = "escherlies@pm.me";
  security.acme.acceptTerms = true;

  services = {
    # grafana configuration
    grafana = {
      enable = true;
      settings.server.http_port = 2342;
      settings.server.http_addr = "127.0.0.1";
      settings.server.domain = "static.156.163.90.157.clients.your-server.de";
    };

    # nginx reverse proxy
    nginx.enable = true;
    nginx.virtualHosts."static.156.163.90.157.clients.your-server.de" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${
            toString config.services.grafana.settings.server.http_port
          }";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
        '';
      };

    };

    prometheus = {
      enable = true;
      port = 9001;

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" "processes" ];
          port = 9002;
        };
      };

      scrapeConfigs = [{
        job_name = "node";
        static_configs = [{
          targets = [
            "127.0.0.1:${
              toString config.services.prometheus.exporters.node.port
            }"
          ];
        }];
      }];
    };

  };

}

