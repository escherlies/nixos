{ pkgs, lib, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.hostName = "nix-debug-1-alice";

  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "debug" ''
      echo "Config: Debug 1 (Alice)"
      echo "Printing the ExecStart script contents of network-local-commands"
      systemctl cat network-local-commands.service | grep "^ExecStart=" | cut -d'=' -f2 | xargs cat
    '')

  ];

}
