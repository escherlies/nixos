# desktop as the remote development machine: the nightshift stack and the
# voice agent run here, as user services that start at boot without a login.
# framework and the phone reach them through the ops-gateway's per-person
# proxy (`ui.enrico.ops.ffilabs.com`, `voice.enrico.ops.ffilabs.com`), which
# connects over wg-ops (./company-vpn.nix admits it on 3115 and 3862); at the
# desk they are on localhost.
#
# The services run each repo's foreground server from its checkout under
# ~/Developer, the same process each repo's `daemon start` forks. Under systemd
# the repos' own `daemon stop|restart|reload` (and `nightshift-update`, which
# calls them) find no PID file and must not be used: `systemctl --user restart
# <name>` restarts a service after an update.
{ pkgs, ... }:

let
  bun = "${pkgs.bun}/bin/bun";
  developer = "%h/Developer";

  # What an interactive fish shell has (home/shells/paths.nix), plus the
  # profile and system paths a login shell adds. The agents nightshift and
  # voice-agent spawn find claude, opencode, git, ffmpeg and the exocortex
  # CLIs here, and ensure-env finds `nix` for its secrets.
  path = builtins.concatStringsSep ":" [
    "%h/.bun/bin"
    "%h/.cargo/bin"
    "${developer}/exocortex/collections/enrico"
    "${developer}/exocortex/collections/exocortex"
    "${developer}/exocortex/collections/integrations"
    "${developer}/exocortex/contrib/enrico"
    "${developer}/_scripts"
    "/run/wrappers/bin"
    "/etc/profiles/per-user/enrico/bin"
    "/run/current-system/sw/bin"
  ];

  service =
    {
      description,
      directory,
      command,
      environment ? [ ],
      extraService ? { },
    }:
    {
      Unit.Description = description;
      Service = {
        WorkingDirectory = "${developer}/${directory}";
        ExecStart = "${bun} run ${command}";
        Environment = [ "PATH=${path}" ] ++ environment;
        Restart = "on-failure";
        RestartSec = 10;
      }
      // extraService;
      Install.WantedBy = [ "default.target" ];
    };
in
{
  # Start enrico's user manager at boot, so the services run without a login.
  users.users.enrico.linger = true;

  home-manager.users.enrico.systemd.user = {
    startServices = "sd-switch";

    services = {
      # Loopback only (its default host): nightshift-ui on this machine is its
      # only HTTP client. Secrets come from its configured envCommand
      # (~/.config/nightshift/config.json).
      nightshift = service {
        description = "nightshift daemon";
        directory = "nightshift";
        command = "src/index.ts serve";
        extraService = {
          # Running tasks are agent processes the daemon spawned. Stopping
          # only the daemon lets them outlive a restart, as they do under the
          # detached `daemon start`, so the restarted daemon can recover them
          # (nightshift README: opencode sessions reattach).
          KillMode = "process";
          TimeoutStopSec = 30;
        };
      };

      # HOST takes one address, so it binds all of them; the firewall admits
      # 3115 only from loopback and the ops-gateway over wg-ops.
      nightshift-ui = service {
        description = "nightshift-ui";
        directory = "nightshift-ui";
        command = "server/cli.ts serve";
        environment = [ "HOST=0.0.0.0" ];
      };

      # voice-agent refuses 0.0.0.0 and checks each address against the live
      # interfaces, exiting if wg-ops is not up yet; a user unit cannot order
      # itself after the system's wireguard-wg-ops, so it retries until it is.
      # The rest mirrors what `voice-agent daemon start` sets (bin/daemon.ts):
      # a strict port, an explicit voice output, and no API keys inherited
      # from the environment, so the Claude Agent SDK uses the subscription.
      voice-agent = service {
        description = "voice-agent";
        directory = "voice-agent";
        command = "bin/voice-agent.ts serve";
        environment = [
          "HOST=127.0.0.1,10.110.1.3"
          "PORT=3862"
          "VOICE_AGENT_VOICE_OUTPUT=client"
        ];
        extraService.UnsetEnvironment = [
          "ANTHROPIC_API_KEY"
          "ANTHROPIC_AUTH_TOKEN"
          "ANTHROPIC_BASE_URL"
          "ELEVENLABS_API_KEY"
          "CLAUDECODE"
          "CLAUDE_CODE_ENTRYPOINT"
        ];
      };

      # As nightshift-actions' own home-manager module (nix/hm-module.nix)
      # declares it. It must run on one machine only: two engines against one
      # nightshift fire every action twice.
      nightshift-actions = service {
        description = "nightshift-actions";
        directory = "nightshift-actions";
        command = "src/index.ts run";
        environment = [ "NIGHTSHIFT_ACTIONS_SCOPE=enrico" ];
        extraService = {
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
  };
}
