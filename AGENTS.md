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

Use `sudo nixos-rebuild switch --flake .#<host>` with the confirmed host name.
Never guess the flake target.
