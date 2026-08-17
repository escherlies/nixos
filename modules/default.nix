{ pkgs, ... }:
{
  imports = [
    ./editors/fresh.nix
    ./ssh.nix
    ./hosts.nix
    ./server-metadata.nix
    ./service-data.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Resolve indirect flake refs (`nixpkgs#bun` in every nix-shebang script) from
  # the local registry only. Nix otherwise downloads the global registry from
  # channels.nixos.org before consulting any entry — even though
  # /etc/nix/registry.json already pins `nixpkgs` to this system's nixpkgs
  # (nixpkgs.flake.setFlakeRegistry, on by default for flake-built systems).
  # During the 2026-08-17 channels.nixos.org outage that download cost 355s on
  # *every* script invocation (5 retries, then fallback to the cached copy).
  # Empty = global registry disabled; the local pin still resolves and the
  # binary cache is unaffected (unlike `nix shell --offline`, which also
  # disables substituters and forces local builds).
  nix.settings.flake-registry = "";

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 90d";
  };

  # Optimize Nix store automatically
  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    # Core utilities
    fish
    # fresh is configured via editors/fresh.nix
    git

    # Documentation & system info
    tealdeer # tldr replacement - simplified man pages
    nitch # minimal system info

    # System monitoring
    ctop # container monitoring
    bottom # system resource monitor (btm)
    htop # already enabled via programs.htop below

    # File & text search
    ripgrep # fast recursive grep (rg)
    fd # modern find alternative
    tree # directory tree visualization

    # File operations
    zip
    unzip # archive extraction

    # Terminal productivity
    fzf # fuzzy finder for cli
    just # command runner

    # Disk usage
    ncdu # interactive disk usage analyzer
    duf # better df for disk usage

    # Network tools
    wget # download files
    nmap # network scanning
    dig # dns queries

    # Cloud & APIs
    hcloud # hetzner cloud cli
    jq # json processor
  ];

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  programs.bat.enable = true;

  programs.htop = {
    enable = true;
    settings.tree_view = true;
  };

  # Trust the local CA root certificate on all machines
  security.pki.certificateFiles = [ ../secrets/local_ca.crt ];

  # Raise inotify limits so file-watching dev tools (editors, bundlers,
  # dev servers) don't hit "ENOSPC: System limit for number of file watchers".
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };
}
