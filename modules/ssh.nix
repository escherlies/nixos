{ ... }:
{

  # SSH Config

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6otvUYmTVJbNBQylV8kBtHSS4AUVQcN68xZZDowpxR enrico@thinkpad"
  ];

  users.users.enrico.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6otvUYmTVJbNBQylV8kBtHSS4AUVQcN68xZZDowpxR enrico@thinkpad"
  ];
}
