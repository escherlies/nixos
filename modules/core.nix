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
    nitch
    ctop
    bottom
    unzip
    just
    hcloud
    git-igitt

  ];

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  programs.bat.enable = true;

  programs.htop = {
    enable = true;
    settings.tree_view = true;
  };

}
