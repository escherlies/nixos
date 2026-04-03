# Agenix secrets declaration
# Public SSH keys of machines that should be able to decrypt each secret
let
  # Machine host keys (get these with: ssh-keyscan <host> | grep ed25519)
  home-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIj/XCYf/xmuPRD4TmDv3iBoVCtm5NwrwI8rsk24TDM6";
  framework = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIsi0Q1fnYWAmJwPT/FeNqShZgn4z/23APCpazZmTcQ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCJOEu1nPXQaHgcaZQLjjAycUxVjqrvJocYdI/NM3kK"
  ];
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsJjCECpF/sagPMgZx5R7hXrQDXBvN0RGJ9dVDGh3gg";
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB8QWrHthWO/Ldkn+xyqyhPLBtpCsiQQIhb+afexN/zi";

  vpn-gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOLUfDXFXdsO9zudZ3FqX3Fj4kF1gRfFH6j6bWfNIA2";
in
{
  "local_ca.key.age".publicKeys = framework ++ [
    home-server
    desktop
  ];

  "user.env.age".publicKeys = framework ++ [
    home-server
    desktop
    laptop
  ];

  # OpenCode environment (API keys)
  "opencode.env.age".publicKeys = framework ++ [
    desktop
  ];

  # WireGuard private keys — each machine can only decrypt its own key
  "wg-vpn-gateway.key.age".publicKeys = [ vpn-gateway ];
  "wg-home-server.key.age".publicKeys = [ home-server ];
  "wg-desktop.key.age".publicKeys = [ desktop ];
  "wg-framework.key.age".publicKeys = framework;
  "wg-laptop.key.age".publicKeys = [ laptop ];

  # ProtonVPN WireGuard private key — only home-server needs it
  "protonvpn.key.age".publicKeys = [ home-server ];

}
