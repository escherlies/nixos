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

      # Secret key used for signing data source settings like secrets and passwords. Set this to a unique, random string in production, generated for example by running openssl rand -hex 32.
      # If you change this later you will need to update data source settings to re-encode them.
      # https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#secret_key
      # Please note that the contents of this option will end up in a world-readable Nix store. Use the file provider pointing at a reasonably secured file in the local filesystem to work around that. Look at the documentation for details: https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#file-provider
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
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

  services.caddy.virtualHosts."${config.network.services.grafana.dns}".extraConfig = ''
    tls internal
    handle /api/blocking/* {
      reverse_proxy 127.0.0.1:${toString blockyPort}
    }
    handle {
      reverse_proxy 127.0.0.1:${toString grafanaPort}
    }
  '';
}
