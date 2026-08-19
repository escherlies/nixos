{ ... }:
{

  # SSH Config

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Every machine name resolves to a LAN *and* a VPN address (modules/hosts.nix)
  # and ssh walks them serially. Without a bound, an address that is up but not
  # answering — a WireGuard tunnel without a handshake, say — costs the kernel's
  # full ~2 minute TCP timeout before ssh even tries the second address, which
  # reads as "ssh desktop is broken". Five seconds is ample for both paths
  # (4 ms on the LAN, ~95 ms through the VPN hub).
  #
  # ServerAlive makes an already-established session notice the same failure
  # instead of hanging until the user kills the terminal.
  programs.ssh.extraConfig = ''
    ConnectTimeout 5
    ServerAliveInterval 15
    ServerAliveCountMax 4
  '';

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6otvUYmTVJbNBQylV8kBtHSS4AUVQcN68xZZDowpxR enrico@thinkpad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIsi0Q1fnYWAmJwPT/FeNqShZgn4z/23APCpazZmTcQ enrico@framework"
  ];

  users.users.enrico.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6otvUYmTVJbNBQylV8kBtHSS4AUVQcN68xZZDowpxR enrico@thinkpad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIsi0Q1fnYWAmJwPT/FeNqShZgn4z/23APCpazZmTcQ enrico@framework"
  ];
}
