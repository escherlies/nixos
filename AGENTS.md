# NixOS configuration — agent rules

## ALWAYS verify the current machine before making changes

This repo configures multiple machines under `machines/`:

- `machines/desktop/`
- `machines/laptop/`
- `machines/framework/`
- (plus any others present in the directory)

The user runs this configuration on **one specific machine at a time**. Which
machine you are on changes which `configuration.nix` is authoritative, which
hardware modules apply, and where machine-specific overrides belong.

### The rule

Before referencing, reading, or editing anything under `machines/<host>/`, you
MUST run `hostname` (via Bash) to determine which host you are actually on.
Do this at the start of any task that could touch machine-specific config.

Do NOT:

- Assume the host from recent git activity, recent commits, or the alphabetical
  order of the `machines/` directory.
- Pick a machine because it was the first one a search tool surfaced.
- Say "the desktop machine" or any other host name without having confirmed
  it via `hostname` in this session.

### When the change is in a shared module

Many edits land in shared modules (`modules/`, `configs/`) that are imported
by multiple machines. That is fine — but you still must confirm the host
first, because:

1. The user expects you to know which machine they are sitting at.
2. You need to know which machine's `configuration.nix` to check the imports
   in, to confirm your shared-module edit will actually apply.
3. Rebuild commands and validation steps are host-specific.

### Rebuilding

**Never write a bare `sudo nixos-rebuild switch --flake .#<host>`.** It is the
one command in this repo that silently destroys the wrong machine: run with
`.#desktop` while sitting at the framework and you activate desktop's
configuration — its hostname, its hardware modules, its bootloader entries — on
the framework. The command looks correct in isolation, which is exactly what
makes it dangerous to paste.

Every command you hand the operator must state, in the command itself, which
machine it runs on. A reader who pastes it into the wrong terminal must get an
error, not a deployment.

Use the recipes that already exist:

| Intent | Command | Why it is safe |
| --- | --- | --- |
| Rebuild the machine you are sitting at | `just rebuild` | Resolves `.#$(hostname)` — cannot target another machine |
| Deploy to another machine | `just rebuild-<host>` | Deploys over SSH and refuses if the box that answers is not `<host>` |

When no recipe fits and you must write the command out:

- Local activation: `sudo nixos-rebuild switch --flake .#"$(hostname)"` — never
  a literal machine name.
- Remote activation: wrap it so the target is visible and enforced, either
  `nixos-rebuild switch --flake .#<host> --target-host root@<host>` (the flake
  target and the SSH target must be the same name — a mismatch is the bug) or
  `ssh <host> 'sudo nixos-rebuild switch --flake .#"$(hostname)"'`.

The same applies to anything else that changes machine state — `systemctl`,
`rm` under `/var/lib`, `wg set`. Write it as `ssh <host> '…'`, or put the host
on the line above it. Never present a bare command and rely on the surrounding
prose to say where it belongs; prose does not survive a copy-paste.
