{ pkgs, lib, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.hostName = "nix-debug-2-bob";

  # Floating IP
  networking.localCommands = ''
    ip addr add 5.75.209.107 dev enp1s0
  '';

  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "debug" ''
      echo "Config: Debug 2 (Bob) - With networking.localCommands"
      echo "Printing the ExecStart script contents of network-local-commands"
      systemctl cat network-local-commands.service | grep "^ExecStart=" | cut -d'=' -f2 | xargs cat
    '')

  ];

}
