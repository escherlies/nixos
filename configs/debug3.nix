{ pkgs, lib, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.hostName = "nix-debug-3-charlie";

  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "debug" ''
      echo "Config: Debug 3 (Charlie)"
      echo "Printing the ExecStart script contents of network-local-commands"
      systemctl cat network-local-commands.service | grep "^ExecStart=" | cut -d'=' -f2 | xargs cat
    '')

  ];

}
