# Agenix secrets declaration
# Public SSH keys of machines that should be able to decrypt each secret
let
  # Machine host keys (get these with: ssh-keyscan <host> | grep ed25519)
  home-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIj/XCYf/xmuPRD4TmDv3iBoVCtm5NwrwI8rsk24TDM6";
  framework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIsi0Q1fnYWAmJwPT/FeNqShZgn4z/23APCpazZmTcQ";
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsJjCECpF/sagPMgZx5R7hXrQDXBvN0RGJ9dVDGh3gg";
in
{
  "secrets/local_ca.key.age".publicKeys = [
    home-server
    framework
    desktop
  ];
}
