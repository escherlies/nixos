{ pkgs, ... }:
{
  # Some config that should apply to every system

  imports = [
    ./editors/nvim.nix
    ./ssh.nix

  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    fish
    neovim
    git
    tealdeer # tldr replacement
    neofetch
    ctop
    bottom
    unzip
    just
    hcloud
    git-igitt

  ];

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
}
