let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico1"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINFV5Soberv3DZBGXE3RcIs+DAOMn+yWrzSXUAqjT4r enrico2"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3YsBfgCcmAN3/IBUZBnSVtHa8C/Rx69u46ckegbiHK enrico@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJsJjCECpF/sagPMgZx5R7hXrQDXBvN0RGJ9dVDGh3gg root@nixos"
  ];
in
{
  "secret1.age".publicKeys = keys;
}
