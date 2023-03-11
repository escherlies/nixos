{ config, pkgs, lib, ... }:

{
  services = {
    # grafana configuration
    grafana = {
      enable = true;
      port = 2342;
      addr = "127.0.0.1";
    };

    # nginx reverse proxy
    nginx.virtualHosts."static.156.163.90.157.clients.your-server.de" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
        proxyWebsockets = true;
      };
    };

    services.prometheus = {
      enable = true;
      port = 9001;

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };

      scrapeConfigs = [{
        job_name = "chrysalis";
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

