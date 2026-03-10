# Auto-Suspend & Wake-on-LAN Gateway

The desktop (RX 7800 XT, running Ollama/OpenCode/WebUI) automatically suspends when idle
and wakes transparently when any of its services are accessed.

## Architecture

```
Client → DNS (ollama.lan → home-server) → Caddy forward_auth → WoL gateway
  ├── Desktop awake? → 200 → reverse_proxy → desktop:port
  └── Desktop asleep? → WoL magic packet → wait → 200 → reverse_proxy → desktop:port
```

## Modules

### `modules/auto-suspend.nix` — Activity-based auto-suspend (desktop)

A systemd timer that checks every 2 minutes whether the desktop is idle.
After a configurable idle period (default: 15 min), it suspends the system.

**Activity checks (any one prevents suspend):**

- Active Ollama inference (via `/api/ps` — models with future `expires_at`)
- External TCP connections to service ports (11434, 8080, 4096, 4097)
- SSH sessions (via `who`)
- Non-idle graphical sessions (via `loginctl`)

**Polkit:**

- Root / systemd services **can** suspend (needed for the timer)
- GNOME / GDM / user sessions **cannot** auto-suspend (we control it ourselves)

**Options:**

| Option                                       | Default                   | Description                             |
| -------------------------------------------- | ------------------------- | --------------------------------------- |
| `services.auto-suspend.enable`               | false                     | Enable activity-based auto-suspend      |
| `services.auto-suspend.idleMinutes`          | 15                        | Minutes of inactivity before suspending |
| `services.auto-suspend.checkIntervalMinutes` | 2                         | How often to check (minutes)            |
| `services.auto-suspend.servicePorts`         | [11434, 8080, 4096, 4097] | Ports to monitor for active connections |

### `modules/wol-gateway.nix` — Wake-on-LAN proxy (home-server)

A small Python HTTP server on localhost. Caddy uses `forward_auth` to call the gateway
before proxying to the desktop. If the desktop is asleep, the gateway sends a WoL magic
packet and waits for it to come up.

**Flow:**

1. Request arrives at home-server Caddy (e.g. `ollama.lan`)
2. `forward_auth` → WoL gateway (`localhost:9009`)
3. Gateway checks desktop reachability (TCP connect to port 22)
4. If unreachable → send WoL magic packet, poll for up to 30s
5. On success → 200 → Caddy reverse-proxies to the desktop service
6. On timeout → 503

**Options:**

| Option                                    | Default | Description                           |
| ----------------------------------------- | ------- | ------------------------------------- |
| `services.wol-gateway.enable`             | false   | Enable the WoL gateway                |
| `services.wol-gateway.listenPort`         | 9009    | Gateway HTTP port (localhost only)    |
| `services.wol-gateway.wakeTimeoutSeconds` | 30      | Max seconds to wait for wake-up       |
| `services.wol-gateway.target.ip`          | —       | Target machine IP                     |
| `services.wol-gateway.target.mac`         | —       | Target NIC MAC address                |
| `services.wol-gateway.target.checkPort`   | 22      | TCP port for liveness check           |
| `services.wol-gateway.proxiedServices`    | {}      | Map of services to proxy (dns + port) |

## Config Changes

### `modules/service-data.nix`

Desktop service DNS (`ollama.lan`, `ai.lan`, `opencode.desktop.lan`) now resolves to
the **home-server** instead of the desktop directly. All traffic goes through the
WoL-aware proxy.

### `machines/desktop/configuration.nix`

- Imports `modules/auto-suspend.nix`
- Enables `services.auto-suspend` (15 min idle threshold)
- Removed the old blanket polkit suspend-block (now handled by auto-suspend module)

### `machines/home-server/configuration.nix`

- Imports `modules/wol-gateway.nix`
- Configures WoL target: desktop at `10.100.0.3`, MAC `d8:43:ae:8e:88:0b`
- Proxies: `ollama.lan:11434`, `ai.lan:8080`, `opencode.desktop.lan:4097`

## Power Profile

| State        | Power draw | Resume time |
| ------------ | ---------- | ----------- |
| Running idle | ~80–120 W  | —           |
| S3 suspend   | ~2–5 W     | ~2–5 s      |
| Shutdown     | ~2–5 W     | ~15–30 s    |

## Deployment

Deploy to both machines:

```sh
# Desktop
nixos-rebuild switch --flake .#desktop

# Home server
nixos-rebuild switch --flake .#home-server --target-host home-server
```

## Manual controls

```sh
# Suspend desktop manually
zzz                          # fish alias → systemctl suspend

# Wake desktop manually
wakeonlan d8:43:ae:8e:88:0b  # from any machine with wakeonlan

# Check auto-suspend timer
systemctl status auto-suspend-check.timer

# Check WoL gateway (on home-server)
systemctl status wol-gateway
journalctl -u wol-gateway -f
```
