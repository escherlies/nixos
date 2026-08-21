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

  # Applied to both the backup and the prune unit. Confining restic to the
  # low-clocking cores is what actually silences the fan: docs/framework-thermal.md
  # measures the audible surges as short excursions to ~4 GHz on the Zen5 cores,
  # and a cpuset removes those cores from restic's reach entirely. The quota,
  # weights and nice value then keep it from crowding out the desktop while it
  # takes its correspondingly longer time.
  resticResourceLimits = {
    AllowedCPUs = cfg.efficiencyCores;
    CPUQuota = cfg.cpuQuota;
    CPUWeight = 20;
    IOWeight = 20;
    IOSchedulingClass = "idle";
    Nice = 19;
  };

  # Restic takes an exclusive repository lock while pruning, so a backup that
  # starts underneath one fails outright — the failure mode that cost this
  # machine 22 days of backups (docs/framework-thermal.md). Splitting prune onto
  # its own timer reintroduces that possibility, so each unit stands down if the
  # other is mid-run.
  #
  # Exit 1 is an ExecCondition "condition not met" code: systemd records the run
  # as skipped rather than failed, so an overlap is silent and the next timer
  # elapse picks the work back up.
  skipWhileRunning =
    unit:
    toString (
      pkgs.writeShellScript "restic-skip-while-${unit}-runs" ''
        ${config.systemd.package}/bin/systemctl is-active --quiet ${unit} && exit 1
        exit 0
      ''
    );
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

    pruneTimerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
      description = ''
        systemd timer configuration for `forget --prune`.

        Deliberately *not* the backup schedule. Prune is repository
        maintenance, not backup: it rewrites packs that hold a mix of live and
        forgotten blobs, which costs orders of magnitude more CPU than the
        backup that precedes it. Measured on framework 2026-08-21 with prune
        attached to the hourly backup: the backup added 6 MiB and finished in
        85 s, then prune repacked 175,579 blobs / 469 MiB to reclaim 269 MiB,
        saturating all 24 threads at 83 C and 6144 rpm — every hour, mostly
        repacking the same packs it had already repacked the hour before.
      '';
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 3"

        # Repacking is the entire cost of a prune, and both of these bound it.
        #
        # --max-unused raises the tolerated dead weight from restic's 5%
        # default. At 5% of a 169 GiB repo, prune repacks until under 8.5 GiB
        # of unused data remains, so nearly every forgotten snapshot triggers a
        # repack. 10% tolerates ~17 GiB instead — a few cents a month of S3 for
        # a large cut in repack volume.
        #
        # --max-repack-size makes a single run's work bounded rather than
        # open-ended: prune stops once it has rewritten this much and the next
        # run continues from there, so a backlog can never become an hour-long
        # CPU storm.
        "--max-unused 10%"
        "--max-repack-size 2G"
      ];
      description = "Restic forget/prune retention policy and repack bounds";
    };

    efficiencyCores = lib.mkOption {
      type = lib.types.str;
      default = "4-11,16-23";
      description = ''
        systemd `AllowedCPUs` mask confining restic to the CPUs whose firmware
        ceiling is low enough not to spin the fan.

        On the framework's Ryzen AI 9 HX 370 the two core types have different
        hardware ceilings: the Zen5 cores (CPUs 0-3 and their SMT siblings
        12-15) boost to 5.16 GHz, the Zen5c cores (4-11, 16-23) top out at
        3.29 GHz. docs/framework-thermal.md establishes that on this chassis a
        `scaling_max_freq` cap is only a hint the hardware may exceed, so a
        frequency ceiling cannot be set from userspace — but `AllowedCPUs` is a
        cpuset, a hard scheduler constraint, and the cores it leaves available
        physically cannot clock past 3.29 GHz. Selecting cores is how you get
        the frequency ceiling that document says does not exist.

        This is a physical CPU numbering and the kernel is free to enumerate
        differently after an update. Re-derive with:
          lscpu -e=CPU,CORE,MAXMHZ
        and take the CPU column of every row at the *lower* MAXMHZ.
      '';
    };

    cpuQuota = lib.mkOption {
      type = lib.types.str;
      default = "400%";
      description = ''
        systemd `CPUQuota` for the backup and prune units — 400% is four of the
        sixteen threads left available by efficiencyCores.

        The backup itself averages ~1.2 cores and is unaffected; this exists to
        cap the prune, which will otherwise take every thread it is given.
        Raise it to trade fan noise back for a shorter prune.
      '';
    };

    maxWorkerThreads = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = ''
        `GOMAXPROCS` for restic. Its repack and pack-upload worker pools are
        sized from GOMAXPROCS, so without this restic starts a worker per
        visible CPU and they merely contend for the cpuQuota slice. Keep it
        equal to cpuQuota's whole-core count.
      '';
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
      # `restic unlock` first: an interrupted run (suspend, reboot, OOM) leaves
      # an exclusive lock behind, and every subsequent run then fails to take
      # its own lock. Because the unit's pre-start is `restic cat config ||
      # restic init`, that surfaces as the *misleading* "repository master key
      # and config already initialized" — so the real cause is invisible and
      # the backup silently stops. This machine lost 22 days of backups that
      # way (stale lock from 2026-07-23, found 2026-08-14), while still paying
      # ~600 MB of SQLite-snapshot writes every hour for a run that could
      # never succeed.
      #
      # `unlock` only removes locks whose owning process is gone, so it cannot
      # disturb a genuinely concurrent run.
      backupPrepareCommand = ''
        ${pkgs.restic}/bin/restic unlock || true
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

      # Prune runs on its own timer — see services.restic-backup.pruneTimerConfig.
      pruneOpts = [ ];

      timerConfig = cfg.timerConfig;
    };

    # Repository maintenance, split off the hourly backup above.
    #
    # `paths = [ ]` with initialize off means the upstream module generates no
    # backup command and no preStart, so this unit's ExecStart is exactly
    # `restic unlock` followed by `restic forget --prune` — the same pair it
    # would have appended to the backup unit, on a schedule of its own.
    services.restic.backups.home-prune = {
      initialize = false;
      paths = [ ];
      environmentFile = config.age.secrets.restic-env.path;
      pruneOpts = cfg.pruneOpts;
      timerConfig = cfg.pruneTimerConfig;
    };

    systemd.services.restic-backups-home-prune = {
      environment = {
        GOMAXPROCS = toString cfg.maxWorkerThreads;

        # Share the backup's cache. The module would otherwise give this unit
        # its own CacheDirectory, leaving prune with a cold index cache that it
        # re-downloads from S3 on every run. mkForce because the upstream
        # module derives both of these from the backup name.
        RESTIC_CACHE_DIR = lib.mkForce "/var/cache/restic-backups-home";
      };

      serviceConfig = resticResourceLimits // {
        CacheDirectory = lib.mkForce "restic-backups-home";
        ExecCondition = skipWhileRunning "restic-backups-home.service";
      };
    };

    systemd.services.restic-backups-home = {
      environment.GOMAXPROCS = toString cfg.maxWorkerThreads;

      serviceConfig = resticResourceLimits // {
        ExecCondition = skipWhileRunning "restic-backups-home-prune.service";
      };
    };

    # Make restic CLI available for manual operations (snapshots, restore, etc.)
    # sqlite3 is needed by the snapshot step above and for inspecting restores.
    environment.systemPackages = [
      pkgs.restic
      pkgs.sqlite
    ];
  };
}
