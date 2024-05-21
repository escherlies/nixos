{ pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix

  ];

  system.stateVersion = "23.11";

  boot.tmp.cleanOnBoot = true;

  zramSwap.enable = true;

  networking.hostName = lib.mkDefault "nixe-base";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # SSH Config

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico1"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINFV5Soberv3DZBGXE3RcIs+DAOMn+yWrzSXUAqjT4r enrico2"
  ];

  programs.ssh.extraConfig = ''
    Host *
        IdentityFile /etc/ssh/ssh_host_ed25519_key
  '';

  environment.systemPackages = with pkgs; [
    fish
    neovim
    git
    tldr
    neofetch
    ctop
    bottom

  ];

  programs = {
    fish.enable = true;

    neovim.enable = true;
    neovim.viAlias = true;
    neovim.vimAlias = true;
    neovim.defaultEditor = true;
    neovim.configure = {
      customRC = ''
        set number
        set relativenumber
      '';
    };
  };

  users.defaultUserShell = pkgs.fish;
}
