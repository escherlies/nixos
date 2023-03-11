{ config, pkgs, lib, ... }:

{
  services = {
    prometheus = {
      enable = true;
      scrapeConfigs = [{
        jobName = "node";
        scrapeInterval = "15s";
        staticConfigs = [{ targets = [ "localhost:9100" ]; }];
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
