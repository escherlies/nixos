{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.opencode;
in
{
  options.services.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent (server + web)";

    package = lib.mkPackageOption pkgs "opencode" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "enrico";
      description = "User account under which opencode runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group under which opencode runs.";
    };

    workDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}";
      description = "Working directory for the opencode server (project root).";
    };

    server = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 4096;
        description = "Port for the opencode headless API server.";
      };

      hostname = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Hostname for the opencode API server to listen on.";
      };
    };

    web = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 4097;
        description = "Port for the opencode web UI.";
      };

      hostname = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Hostname for the opencode web UI to listen on.";
      };
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Environment variables passed to both opencode services.
        Useful for setting API keys, OPENCODE_SERVER_PASSWORD, etc.
      '';
      example = {
        OPENCODE_SERVER_PASSWORD = "secret";
        ANTHROPIC_API_KEY = "sk-...";
      };
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to an environment file with secrets (e.g. API keys).
        Loaded by systemd's EnvironmentFile= directive.
      '';
    };

    caddy = {
      enable = lib.mkEnableOption "Caddy reverse proxy for the OpenCode web UI";
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services.opencode-server = {
      description = "OpenCode API Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = lib.concatStringsSep " " [
          "${cfg.package}/bin/opencode"
          "serve"
          "--port ${toString cfg.server.port}"
          "--hostname ${cfg.server.hostname}"
        ];
        WorkingDirectory = cfg.workDir;
        StateDirectory = "opencode";
        StateDirectoryMode = "0750";
        Restart = "on-failure";
        RestartSec = 5;
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };

      environment = cfg.environment;
    };

    systemd.services.opencode-web = {
      description = "OpenCode Web UI";
      after = [
        "network.target"
        "opencode-server.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = lib.concatStringsSep " " [
          "${cfg.package}/bin/opencode"
          "web"
          "--port ${toString cfg.web.port}"
          "--hostname ${cfg.web.hostname}"
        ];
        WorkingDirectory = cfg.workDir;
        StateDirectory = "opencode";
        StateDirectoryMode = "0750";
        Restart = "on-failure";
        RestartSec = 5;
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };

      environment = cfg.environment;
    };

    # Caddy reverse proxy for the web UI (optional)
    services.caddy.virtualHosts = lib.mkIf cfg.caddy.enable {
      "${config.network.services.opencode.dns}".extraConfig = ''
        tls internal
        reverse_proxy 127.0.0.1:${toString cfg.web.port}
      '';
    };
  };
}
