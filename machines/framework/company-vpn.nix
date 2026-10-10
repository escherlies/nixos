# framework on the company VPN's `wg-ops` tunnel as workstation 10.110.1.1,
# next to the personal VPN's wg0 (modules/wireguard.nix). The client side comes
# from binp-nixos-infra: task/0031-company-vpn-and-builder.md step 8 there.
#
# The tunnel shows up in NetworkManager and can be disconnected there
# (hideFromNetworkManager stays at the module's default, false);
# `sudo systemctl restart wireguard-wg-ops` or a reboot brings it back.
{
  config,
  inputs,
  ...
}:

let
  opsNetwork = config.services.company-vpn.opsNetwork;

  # What the ops-gateway's Caddy proxies to for the phone
  # (binp-nixos-infra task/0032-phone-access-and-personal-stacks.md step 7).
  gatewayProxiedTcpPorts = [
    3862 # voice-agent daemon
    3115 # nightshift-ui
  ];
  gatewayProxiedTcpPortList = builtins.concatStringsSep "," (map toString gatewayProxiedTcpPorts);
in
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

  # Only the gateway may reach these ports through wg-ops. 3862 is already open
  # on every interface for the LAN dev range in ./configuration.nix, so the
  # refusal for every other wg-ops source is inserted ahead of those accepts;
  # the accept for the gateway is appended. The hub would forward the builder
  # (10.110.0.2) to a workstation, so this is not only belt and braces.
  networking.firewall.extraCommands = ''
    iptables -w -I nixos-fw 1 -i ${opsNetwork.interfaceName} ! -s ${opsNetwork.hubAddress} \
      -p tcp -m multiport --dports ${gatewayProxiedTcpPortList} -j nixos-fw-log-refuse
    iptables -w -A nixos-fw -i ${opsNetwork.interfaceName} -s ${opsNetwork.hubAddress} \
      -p tcp -m multiport --dports ${gatewayProxiedTcpPortList} -j nixos-fw-accept
  '';
}
