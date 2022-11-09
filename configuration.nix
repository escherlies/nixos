{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix

  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "nixe";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico1"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINFV5Soberv3DZBGXE3RcIs+DAOMn+yWrzSXUAqjT4r enrico2"
  ];

  environment.systemPackages = [
    pkgs.fish
    pkgs.neovim

  ];

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
}
