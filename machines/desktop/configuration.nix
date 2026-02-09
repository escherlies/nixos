# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/desktops/gnome.nix
    ../../modules/ollama.nix
    ../../modules/webui.nix
    ../../configs/ai-agents.nix
    ../../modules/machines.nix

  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
    options = "ctrl:swap_lwin_lctl";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # For easyeffects (See file://./../home/audio.nix)
  programs.dconf.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.enrico = {
    isNormalUser = true;
    description = "enrico";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
      # kdePackages.kate
      #  thunderbird
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Enable Caddy for reverse proxy
  services.caddy.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    80
    1234
    4321
    3333
    8000
    8081

    # 8088 # WebUI via services.open-webui.openFirewall = true;
    # 11434 # Ollama via services.ollama.openFirewall = true;
  ];

  # VPN Connections
  networking.firewall.checkReversePath = "loose";

  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Machine specific metadata
  server.metadata.ipv4 = config.machines.desktop.ipv4;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  # hardware.keyboard.qmk.enable = true;

  services.udev.packages = [
    # pkgs.via
    pkgs.qmk-udev-rules # For QMK/Via
  ];

  services.libinput.mouse.accelProfile = "flat";

  nixpkgs.config.allowUnfree = true;

  # WOL (https://wiki.archlinux.org/title/Wake-on-LAN)
  # ip link -> get device interface + mac adress
  # sudo ethtool <interface> | grep Wake-on
  # Enable wol in bios
  # Enable in nix config on target machine:
  networking.interfaces.enp14s0.wakeOnLan.enable = true;
  # Run wakeonlan <mac adress> to wakey wakey

  # Disable autoSuspend
  services.displayManager.gdm.autoSuspend = false;
  # ^ This not working, additionally we need this...
  # https://discourse.nixos.org/t/why-is-my-new-nixos-install-suspending/19500/2
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
        {
            return polkit.Result.NO;
        }
    });
  '';

  services.hardware.openrgb.enable = true;
}
