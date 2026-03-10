# Activity-based auto-suspend
#
# Periodically checks if the system is idle (no Ollama activity, no SSH sessions,
# no active GUI sessions, no connections to service ports). After a configurable
# idle period, the system suspends automatically.
#
# Designed for the desktop: keeps the GPU-powered workstation available while in use,
# but suspends it to save power when nobody is actively using it.
# Resume is near-instant (~2-5s) since S3 suspend preserves RAM + VRAM.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.auto-suspend;

  checkScript = pkgs.writeShellScript "auto-suspend-check" ''
    set -euo pipefail

    IDLE_FILE="/var/lib/auto-suspend/idle-since"
    IDLE_THRESHOLD=${toString cfg.idleMinutes}

    # Service ports to monitor for active external connections
    SERVICE_PORTS=(${lib.concatMapStringsSep " " toString cfg.servicePorts})

    is_active() {
      # 1. Check for active Ollama inference (models with ongoing requests)
      local ps_output
      ps_output=$(${pkgs.curl}/bin/curl -sf http://localhost:11434/api/ps 2>/dev/null || echo '{"models":[]}')
      local model_count
      model_count=$(echo "$ps_output" | ${pkgs.jq}/bin/jq '.models | length' 2>/dev/null || echo 0)
      if [[ "$model_count" -gt 0 ]]; then
        # Check if any model was recently active (expires_at in the future = recently used)
        local active
        active=$(echo "$ps_output" | ${pkgs.jq}/bin/jq '[.models[] | select(.expires_at > now)] | length' 2>/dev/null || echo 0)
        if [[ "$active" -gt 0 ]]; then
          return 0
        fi
      fi

      # 2. Check for external TCP connections to service ports
      for port in "''${SERVICE_PORTS[@]}"; do
        if ${pkgs.iproute2}/bin/ss -tn state established "( sport = :$port )" 2>/dev/null \
            | grep -v '127.0.0.1' | grep -v '::1' | grep -qv '^State'; then
          return 0
        fi
      done

      # 3. Check for active SSH sessions
      if ${pkgs.coreutils}/bin/who 2>/dev/null | grep -q pts; then
        return 0
      fi

      # 4. Check for active (non-idle) graphical sessions
      for session in $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}'); do
        local idle
        idle=$(${pkgs.systemd}/bin/loginctl show-session "$session" -p IdleHint --value 2>/dev/null || echo "yes")
        if [[ "$idle" == "no" ]]; then
          return 0
        fi
      done

      return 1
    }

    mkdir -p "$(dirname "$IDLE_FILE")"

    if is_active; then
      # System is active — reset idle timer
      date +%s > "$IDLE_FILE"
      exit 0
    fi

    # System is idle — check how long
    if [[ ! -f "$IDLE_FILE" ]]; then
      date +%s > "$IDLE_FILE"
      exit 0
    fi

    idle_since=$(cat "$IDLE_FILE")
    now=$(date +%s)
    idle_minutes=$(( (now - idle_since) / 60 ))

    if [[ "$idle_minutes" -ge "$IDLE_THRESHOLD" ]]; then
      logger -t auto-suspend "System idle for ''${idle_minutes}m (threshold: ''${IDLE_THRESHOLD}m). Suspending."
      # Reset idle timer before suspending so we don't immediately re-suspend on wake
      date +%s > "$IDLE_FILE"
      ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';
in
{
  options.services.auto-suspend = {
    enable = lib.mkEnableOption "activity-based auto-suspend";

    idleMinutes = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Minutes of inactivity before suspending.";
    };

    checkIntervalMinutes = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "How often to check for activity (in minutes).";
    };

    servicePorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        11434 # Ollama
        8080 # Open WebUI
        4096 # OpenCode API
        4097 # OpenCode Web
      ];
      description = "TCP ports to monitor for active external connections. Any established connection to these ports counts as activity.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the auto-suspend service can call systemctl suspend
    # even though we block GNOME/GDM from auto-suspending.
    # The polkit rule exempts root (our service runs as root).
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.login1.suspend" ||
              action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
              action.id == "org.freedesktop.login1.hibernate" ||
              action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
          {
              // Allow root / system services to suspend (for auto-suspend)
              if (subject.user == "root") {
                  return polkit.Result.YES;
              }
              // Block everything else (GNOME, GDM, user-initiated)
              return polkit.Result.NO;
          }
      });
    '';

    # Disable GNOME's built-in idle suspend (we handle it ourselves)
    services.desktopManager.gnome.extraGSettingsOverrides = lib.mkAfter ''

      [org.gnome.settings-daemon.plugins.power]
      sleep-inactive-ac-type='nothing'
      sleep-inactive-battery-type='nothing'
    '';

    systemd.services.auto-suspend-check = {
      description = "Check system activity and suspend if idle";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = checkScript;
      };
    };

    systemd.timers.auto-suspend-check = {
      description = "Periodic activity check for auto-suspend";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "${toString cfg.idleMinutes}min";
        OnUnitActiveSec = "${toString cfg.checkIntervalMinutes}min";
        Unit = "auto-suspend-check.service";
      };
    };
  };
}
