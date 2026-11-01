# framework on the company VPN's `wg-ops` tunnel as workstation 10.110.1.1,
# next to the personal VPN's wg0 (modules/wireguard.nix). The client side comes
# from binp-nixos-infra: task/0031-company-vpn-and-builder.md step 8 there.
# framework serves nothing over it: enrico's voice agent and nightshift-ui run
# on desktop (../desktop/company-vpn.nix), and framework reaches them through
# the ops-gateway's proxy like the phone.
#
# The tunnel shows up in NetworkManager and can be disconnected there
# (hideFromNetworkManager stays at the module's default, false);
# `ssh root@framework systemctl restart wireguard-wg-ops` or a reboot brings it
# back.
{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.binp-nixos-infra.nixosModules.company-vpn-workstation ];

  # Public key, for the hub's opsPeers: RA8Ch9Y5l2gUlqMceOvWzWhK6STm4mTMFUSIaRrfkX8=
  age.secrets."wg-ops-framework" = {
    file = ../../secrets/wg-ops-framework.key.age;
    mode = "0400";
  };

  services.company-vpn.client = {
    address = "10.110.1.1";
    privateKeyFile = config.age.secrets."wg-ops-framework".path;
  };
}
