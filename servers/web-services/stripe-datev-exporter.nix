{ lib, pkgs, config, ... }:
with lib;
let
  # Shorter name to access final settings a 
  # user of stripe-datev-exporter.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.stripe-datev-exporter;
in {
  # Declare what settings a user of this "stripe-datev-exporter.nix" module CAN SET.
  options.services.stripe-datev-exporter = {
    enable = mkEnableOption "stripe-datev-exporter service";
  };

  config = mkIf cfg.enable {

    # Invoices
    systemd.timers."stripe-datev-exporter" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-01 12:00:00";
        Unit = "stripe-datev-exporter.service";
      };
    };

    systemd.services."stripe-datev-exporter" = {
      script = ''
        set -eu
        ${pkgs.docker}/bin/docker run --env-file /root/.data/stripe-datev-exporter.env ghcr.io/binaryplease/stripe-datev-exporter/app:latest
      '';
      requires = [
        "docker.service"

      ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
