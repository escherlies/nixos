# Wake-on-LAN gateway for suspended machines
#
# Runs a small HTTP health-gate service on an always-on machine (e.g. home-server).
# When Caddy receives a request for a desktop service, it first calls forward_auth
# to this gateway. The gateway checks if the target machine is reachable:
#   - If yes → returns 200 immediately
#   - If no  → sends a WoL magic packet, waits for the machine to come up, returns 200
#   - On timeout → returns 503
#
# This enables transparent wake-on-demand: access ollama.lan from anywhere and the
# desktop wakes up automatically.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.wol-gateway;

  gatewayScript = pkgs.writers.writePython3 "wol-gateway" { } ''
    import http.server
    import socket
    import subprocess
    import time
    import json
    import sys

    TARGET_IP = "${cfg.target.ip}"
    TARGET_MAC = "${cfg.target.mac}"
    CHECK_PORT = ${toString cfg.target.checkPort}
    WAKE_TIMEOUT = ${toString cfg.wakeTimeoutSeconds}
    LISTEN_PORT = ${toString cfg.listenPort}

    def is_alive():
        """Quick TCP connect to check if target is reachable."""
        try:
            s = socket.create_connection((TARGET_IP, CHECK_PORT), timeout=2)
            s.close()
            return True
        except (OSError, ConnectionRefusedError, socket.timeout):
            return False

    def send_wol():
        """Send Wake-on-LAN magic packet via wakeonlan."""
        subprocess.run(
            ["${pkgs.wakeonlan}/bin/wakeonlan", TARGET_MAC],
            capture_output=True,
        )

    def wake_and_wait():
        """Send WoL and poll until target is reachable or timeout."""
        send_wol()
        start = time.monotonic()
        while time.monotonic() - start < WAKE_TIMEOUT:
            time.sleep(2)
            if is_alive():
                # Give services a moment to be fully ready after resume
                time.sleep(1)
                return True
        return False

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.handle_request()

        def do_POST(self):
            self.handle_request()

        def do_HEAD(self):
            self.handle_request()

        def handle_request(self):
            if is_alive():
                self.send_response(200)
                self.send_header("X-WoL-Status", "already-awake")
                self.end_headers()
                return

            print(f"Target {TARGET_IP} unreachable. Sending WoL to {TARGET_MAC}...",
                  file=sys.stderr, flush=True)
            if wake_and_wait():
                print(f"Target {TARGET_IP} is now awake.", file=sys.stderr, flush=True)
                self.send_response(200)
                self.send_header("X-WoL-Status", "woken-up")
                self.end_headers()
            else:
                print(f"Target {TARGET_IP} did not wake up within {WAKE_TIMEOUT}s.",
                      file=sys.stderr, flush=True)
                self.send_response(503)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"Desktop did not wake up in time.\n")

        def log_message(self, format, *args):
            # Use stderr for logging (captured by systemd journal)
            print(f"wol-gateway: {format % args}", file=sys.stderr, flush=True)

    server = http.server.HTTPServer(("127.0.0.1", LISTEN_PORT), Handler)
    print(f"WoL gateway listening on 127.0.0.1:{LISTEN_PORT}", file=sys.stderr, flush=True)
    print(f"  Target: {TARGET_IP} (MAC: {TARGET_MAC})", file=sys.stderr, flush=True)
    print(f"  Check port: {CHECK_PORT}, Wake timeout: {WAKE_TIMEOUT}s", file=sys.stderr, flush=True)
    server.serve_forever()
  '';

in
{
  options.services.wol-gateway = {
    enable = lib.mkEnableOption "Wake-on-LAN gateway for transparent service wake-up";

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 9009;
      description = "Port for the WoL gateway HTTP server (localhost only).";
    };

    wakeTimeoutSeconds = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Maximum seconds to wait for the target to wake up.";
    };

    target = {
      ip = lib.mkOption {
        type = lib.types.str;
        description = "IP address of the target machine to wake (LAN or VPN IP).";
      };

      mac = lib.mkOption {
        type = lib.types.str;
        description = "MAC address of the target machine's NIC (for Wake-on-LAN).";
        example = "AA:BB:CC:DD:EE:FF";
      };

      checkPort = lib.mkOption {
        type = lib.types.port;
        default = 22;
        description = "TCP port to check for liveness (SSH is a good default — comes up fast after resume).";
      };
    };

    # Services to proxy through the WoL gateway
    proxiedServices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            dns = lib.mkOption {
              type = lib.types.str;
              description = "DNS hostname for this service.";
            };
            targetPort = lib.mkOption {
              type = lib.types.port;
              description = "Port on the target machine where the service runs.";
            };
            targetIp = lib.mkOption {
              type = lib.types.str;
              default = cfg.target.ip;
              description = "IP to proxy to (defaults to target.ip).";
            };
          };
        }
      );
      default = { };
      description = "Services to expose via Caddy with WoL-backed reverse proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The gateway service
    systemd.services.wol-gateway = {
      description = "Wake-on-LAN HTTP gateway";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = gatewayScript;
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        # AmbientCapabilities: none needed — WoL uses UDP broadcast (no raw sockets)
      };
    };

    # Caddy virtual hosts: forward_auth → WoL gateway, then reverse_proxy to target
    services.caddy.virtualHosts = lib.mapAttrs' (
      _name: svc:
      lib.nameValuePair svc.dns {
        extraConfig = ''
          tls internal

          # Ensure the desktop is awake before proxying
          forward_auth 127.0.0.1:${toString cfg.listenPort} {
            uri /wake
          }

          reverse_proxy ${svc.targetIp}:${toString svc.targetPort} {
            # Give services a moment to fully start after resume
            lb_try_duration 15s
            lb_try_interval 2s
          }
        '';
      }
    ) cfg.proxiedServices;
  };
}
