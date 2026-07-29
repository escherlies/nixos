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

  # Runtime exclude files written by backupPrepareCommand
  largeDownloadsExclude = "/run/restic-large-downloads.exclude";
  sqliteExclude = "/run/restic-sqlite.exclude";

  # Takes a consistent snapshot of every matched SQLite database using the
  # online backup API, mirroring the source path under cfg.sqliteSnapshotDir.
  #
  # Why this is necessary: a WAL-mode database is *three* files (db, -wal,
  # -shm) and restic reads them at different points in time. A live writer
  # between those reads yields a torn, unrestorable set — and for a freshly
  # checkpointed database the main file can be near-empty with all the real
  # data still sitting in the -wal.
  #
  # `.backup` (not `VACUUM INTO`) is used deliberately: it preserves the page
  # layout, so consecutive snapshots differ only where the data changed and
  # restic deduplicates them well. VACUUM INTO repacks every page and would
  # upload an essentially new file each run.
  #
  # The copy runs via `runuser` as the database's owner: a read-only SQLite
  # connection creates a -shm (and empty -wal) next to the source and does not
  # remove them on close, so doing this as root would leave root-owned files in
  # the user's data directory and break the owning application.
  sqliteSnapshotScript = pkgs.writeShellScript "restic-sqlite-snapshot" ''
    set -uo pipefail
    export PATH=${
      lib.makeBinPath [
        pkgs.sqlite
        pkgs.coreutils
        pkgs.findutils
        pkgs.util-linux
      ]
    }
    shopt -s nullglob

    dest="${cfg.sqliteSnapshotDir}"
    exclude="${sqliteExclude}"

    install -d -m 0755 "$dest"
    : > "$exclude"

    patterns=(${lib.escapeShellArgs cfg.sqliteDatabases})

    for pattern in ''${patterns[@]+"''${patterns[@]}"}; do
      for db in $pattern; do
        [ -f "$db" ] || continue

        owner=$(stat -c %U "$db")
        out="$dest/''${db#/}"
        tmp="$out.restic-tmp"
        outdir="$(dirname "$out")"

        # Leaf directory is owned by the database owner so the unprivileged
        # `runuser` copy below can write into it; parents stay root-owned.
        mkdir -p "$outdir" || continue
        chown "$owner" "$outdir" && chmod 0700 "$outdir" || continue
        rm -f "$tmp" "$tmp-wal" "$tmp-shm"

        # Absolute path: runuser goes through PAM and may reset the environment
        if runuser -u "$owner" -- ${pkgs.sqlite}/bin/sqlite3 -readonly "$db" ".backup '$tmp'"; then
          mv -f "$tmp" "$out"
          rm -f "$tmp-wal" "$tmp-shm"
          # Snapshot succeeded, so skip the live files entirely
          printf '%s\n%s\n%s\n' "$db" "$db-wal" "$db-shm" >> "$exclude"
        else
          # Leave the previous snapshot (if any) in place and fall back to
          # backing up the live files rather than losing the database.
          echo "restic-sqlite: snapshot failed, backing up live files: $db" >&2
          rm -f "$tmp" "$tmp-wal" "$tmp-shm"
        fi
      done
    done

    # Drop snapshots whose source database no longer exists
    find "$dest" -type f -print0 | while IFS= read -r -d "" snap; do
      [ -e "/''${snap#$dest/}" ] || rm -f "$snap"
    done
    find "$dest" -mindepth 1 -type d -empty -delete

    exit 0
  '';
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

    sqliteDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # Firefox profile (history, bookmarks, cookies, logins, form history)
        "/home/enrico/.config/mozilla/firefox/*/*.sqlite"
        "/home/enrico/.config/mozilla/firefox/*/*.db"
        "/home/enrico/.mozilla/firefox/*/*.sqlite"
        "/home/enrico/.mozilla/firefox/*/*.db"

        # Thunderbird (mail index, address book, calendar)
        "/home/enrico/.thunderbird/*/*.sqlite"
        "/home/enrico/.thunderbird/*/calendar-data/*.sqlite"

        # 1Password local vault cache
        "/home/enrico/.config/1Password/*.sqlite"

        # Matrix E2EE crypto store — a torn copy loses message decryption
        "/home/enrico/.local/share/matrix-service/*.db"

        # Editors / terminals / local tools
        "/home/enrico/.local/share/zed/db/*/db.sqlite"
        "/home/enrico/.local/share/waveterm/db/*.db"
        "/home/enrico/.local/share/nightshift/*.sqlite"
        "/home/enrico/.local/share/epiphany/*.db"
      ];
      description = ''
        Glob patterns for SQLite databases that must be snapshotted with the
        online backup API before the backup run, instead of being copied live.

        Required for any WAL-mode database: the main file, -wal and -shm are
        read by restic at different times and a concurrent writer produces an
        inconsistent (often unrestorable) set. Databases listed here are copied
        with `sqlite3 .backup` into sqliteSnapshotDir and the live files are
        excluded from the backup.

        Patterns are shell globs expanded at backup time; non-matching and
        non-SQLite paths are skipped.
      '';
    };

    sqliteSnapshotDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/backup/sqlite";
      description = ''
        Directory holding the consistent SQLite snapshots. Source paths are
        mirrored underneath it, so /home/enrico/.thunderbird/default/places.sqlite
        is restored from <dir>/home/enrico/.thunderbird/default/places.sqlite.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    # Decrypt S3 credentials + repo password
    age.secrets.restic-env = {
      file = ../secrets/restic.env.age;
      owner = "root";
      mode = "0400";
    };

    systemd.tmpfiles.rules = [ "d ${cfg.sqliteSnapshotDir} 0755 root root -" ];

    services.restic.backups.home = {
      initialize = true;

      paths = [
        "/home/enrico"
      ]
      ++ lib.optional (cfg.sqliteDatabases != [ ]) cfg.sqliteSnapshotDir;

      # Credentials come from the environment file:
      # RESTIC_REPOSITORY, RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
      environmentFile = config.age.secrets.restic-env.path;

      # Find files in Downloads larger than 1GB and write them to a temporary exclude file
      # Ignore find errors if files are moved/deleted during the run
      backupPrepareCommand = ''
        ${pkgs.findutils}/bin/find /home/enrico/Downloads -type f -size +1G > ${largeDownloadsExclude} || true
        ${sqliteSnapshotScript}
      '';

      extraBackupArgs = [
        "--exclude-file=${../config/restic-excludes}"
        "--exclude-file=${largeDownloadsExclude}"
        "--exclude-file=${sqliteExclude}"
        "--exclude-caches"
        "--one-file-system"
      ];

      pruneOpts = cfg.pruneOpts;
      timerConfig = cfg.timerConfig;
    };

    # Make restic CLI available for manual operations (snapshots, restore, etc.)
    # sqlite3 is needed by the snapshot step above and for inspecting restores.
    environment.systemPackages = [
      pkgs.restic
      pkgs.sqlite
    ];
  };
}
