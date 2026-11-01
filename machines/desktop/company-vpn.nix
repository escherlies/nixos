# desktop on the company VPN's `wg-ops` tunnel as workstation 10.110.1.3, next
# to the personal VPN's wg0 (modules/wireguard.nix), and serving enrico's
# nightshift stack and voice agent. Both come from binp-nixos-infra
# (`company-vpn-workstation` and `personal-stack`); this file sets only what is
# desktop's own.
#
# The tunnel shows up in NetworkManager and can be disconnected there
# (hideFromNetworkManager stays at the module's default, false);
# `ssh root@desktop systemctl restart wireguard-wg-ops` or a reboot brings it
# back.
{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.binp-nixos-infra.nixosModules.personal-stack ];

  # Public key, for the hub's opsPeers: dO+6umV7K3bj7tIqnVPqZKvyhD71YM5rwlAkNkr0zlE=
  age.secrets."wg-ops-desktop" = {
    file = ../../secrets/wg-ops-desktop.key.age;
    mode = "0400";
  };

  services.company-vpn.client = {
    address = "10.110.1.3";
    privateKeyFile = config.age.secrets."wg-ops-desktop".path;
  };

  services.personal-stack.user = "enrico";
}
