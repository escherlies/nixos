{ config, pkgs, ... }:

let
  prometheusPort = 9090;
  nodeExporterPort = 9100;
  grafanaPort = 3001;
  blockyPort = 4000;
in
{
  services.prometheus = {
    enable = true;
    port = prometheusPort;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = nodeExporterPort;
      };
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString prometheusPort}" ];
          }
        ];
      }
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString nodeExporterPort}" ];
          }
        ];
      }
      {
        job_name = "blocky";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString blockyPort}" ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    # declarativePlugins = with pkgs; [
    #   grafana-piechart-panel
    # ];
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = grafanaPort;
      };
      panels = {
        disable_sanitize_html = true;
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString prometheusPort}";
        }
      ];
    };
  };

  # Open ports in the firewall
  networking.firewall.allowedTCPPorts = [
    grafanaPort
    prometheusPort
    blockyPort
  ];

  # Use reverse proxy
  services.caddy.virtualHosts."http://${config.network.services.grafana.dns}".extraConfig =
    "reverse_proxy 127.0.0.1:${toString grafanaPort}";
}
