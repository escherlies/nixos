# desktop on the company VPN's `wg-ops` tunnel as workstation 10.110.1.3,
# next to the personal VPN's wg0 (modules/wireguard.nix). The client side comes
# from binp-nixos-infra: task/0031-company-vpn-and-builder.md step 8 there, the
# same as ../framework/company-vpn.nix.
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

let
  opsNetwork = config.services.company-vpn.opsNetwork;
in
{
  imports = [ inputs.binp-nixos-infra.nixosModules.company-vpn-workstation ];

  # Public key, for the hub's opsPeers: dO+6umV7K3bj7tIqnVPqZKvyhD71YM5rwlAkNkr0zlE=
  age.secrets."wg-ops-desktop" = {
    file = ../../secrets/wg-ops-desktop.key.age;
    mode = "0400";
  };

  services.company-vpn.client = {
    address = "10.110.1.3";
    privateKeyFile = config.age.secrets."wg-ops-desktop".path;
  };

  # wg-ops admits ping and replies to desktop's own connections; everything
  # else arriving on it is refused before the global accepts in
  # ./configuration.nix, which are meant for the LAN. The hub forwards
  # infrastructure (the builder, 10.110.0.2) to workstations on any port, so
  # without this every globally open port would be open to it. Unlike
  # framework, desktop serves nothing to the gateway's phone proxy, so no port
  # is admitted. wg-ops carries no IPv6, and the IPv6 refusal keeps it that way.
  networking.firewall.extraCommands = ''
    iptables -w -I nixos-fw 1 -i ${opsNetwork.interfaceName} \
      -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept
    iptables -w -I nixos-fw 2 -i ${opsNetwork.interfaceName} \
      -p icmp --icmp-type echo-request -j nixos-fw-accept
    iptables -w -I nixos-fw 3 -i ${opsNetwork.interfaceName} -j nixos-fw-log-refuse
    ip6tables -w -I nixos-fw 1 -i ${opsNetwork.interfaceName} -j nixos-fw-log-refuse
  '';
}
