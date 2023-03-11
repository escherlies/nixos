{ config, pkgs, lib, ... }:

{
  services = {
    prometheus = {
      enable = true;
      scrapeConfigs = [{
        job_name = "node";
        scrape_interval = "15s";
        static_configs = [{ targets = [ "localhost:9100" ]; }];
      }];
    };
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 9100 9090 ];
    };
  };
}
