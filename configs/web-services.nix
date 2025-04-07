{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.hostName = "nixe";

  # Stripe Datev Exporter
  services.stripe-datev-exporter.enable = true;

  # Docker services
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  users.users.root.extraGroups = [ "docker" ];

  # Misc
  nixpkgs.config.allowUnfree = true;
  services.n8n.enable = true;
  systemd.services.n8n.serviceConfig.EnvironmentFile = "/root/.data/n8n.env";

  # Enable Caddy
  # All site configurations are now in the Caddyfile
  services.caddy.enable = true;
  services.caddy.extraConfig = builtins.readFile ./Caddyfile;

}
