{ pkgs, ... }:
{
  imports = [
    ./editors/nvim.nix
    ./ssh.nix
    ./server-metadata.nix
    ./service-data.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
    neovim
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
}
