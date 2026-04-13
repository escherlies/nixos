# Restic backup of /home/enrico to S3-compatible storage.
#
# Secrets are provided via an agenix-encrypted environment file containing:
#   RESTIC_REPOSITORY, RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
#
# See secrets/restic.env.example for the template.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.restic-backup;
in
{
  options.services.restic-backup = {
    enable = lib.mkEnableOption "restic backup of /home/enrico to S3";

    timerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
      description = "systemd timer configuration for the backup schedule";
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
      description = "Restic forget/prune retention policy";
    };
  };

  config = lib.mkIf cfg.enable {

    # Decrypt S3 credentials + repo password
    age.secrets.restic-env = {
      file = ../secrets/restic.env.age;
      owner = "root";
      mode = "0400";
    };

    services.restic.backups.home = {
      initialize = true;

      paths = [ "/home/enrico" ];

      # Credentials come from the environment file:
      # RESTIC_REPOSITORY, RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
      environmentFile = config.age.secrets.restic-env.path;

      # Find files in Downloads larger than 1GB and write them to a temporary exclude file
      # Ignore find errors if files are moved/deleted during the run
      backupPrepareCommand = ''
        ${pkgs.findutils}/bin/find /home/enrico/Downloads -type f -size +1G > /run/restic-large-downloads.exclude || true
      '';

      extraBackupArgs = [
        "--exclude-file=${../config/restic-excludes}"
        "--exclude-file=/run/restic-large-downloads.exclude"
        "--exclude-caches"
        "--one-file-system"
      ];

      pruneOpts = cfg.pruneOpts;
      timerConfig = cfg.timerConfig;
    };

    # Make restic CLI available for manual operations (snapshots, restore, etc.)
    environment.systemPackages = [ pkgs.restic ];
  };
}
