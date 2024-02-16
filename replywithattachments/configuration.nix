{ pkgs, config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix

  ];

  options = {

    machine = {
      subdomain = lib.mkOption {
        type = lib.types.str;
        description = "The subdomain for the service";
      };
    };

  };
  config = {

    system.stateVersion = "23.11";
    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # SSH Config

    networking.firewall.allowedTCPPorts = [ 80 443 ];
    networking.hostName = "ffilabs-${config.machine.subdomain}";

    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;

    users.users.root.openssh.authorizedKeys.keys = [

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGOkHM4m0DhxJCGH4lkSaaun5RYXZg91LAO15RPeXyS enrico1"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINFV5Soberv3DZBGXE3RcIs+DAOMn+yWrzSXUAqjT4r enrico2"
    ];

    programs.ssh.extraConfig = ''
      Host *
          IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';

    programs = {
      fish.enable = true;

      neovim.enable = true;
      neovim.viAlias = true;
      neovim.vimAlias = true;
      neovim.defaultEditor = true;
      neovim.configure = {
        customRC = ''
          set number
          set relativenumber
        '';
      };
    };

    users.defaultUserShell = pkgs.fish;

    # Use NGINX as reverse proxy
    security.acme.defaults.email =
      "no-reply@${config.machine.subdomain}.replywithattachments.com";
    security.acme.acceptTerms = true;
    security.acme.defaults.server =
      "https://acme-staging-v02.api.letsencrypt.org/directory";

    virtualisation.docker.enable = true;

    environment.systemPackages = with pkgs; [

      bottom
      ctop
      docker-compose
      fish
      git
      neovim
      tldr
    ];

    users.users.root.extraGroups = [ "docker" ];

    # Nginx
    services.nginx.enable = true;
    services.nginx.recommendedProxySettings = true;
    services.nginx.recommendedTlsSettings = true;

    # Reply with Attachments
    services.nginx.virtualHosts."${config.machine.subdomain}.replywithattachments.com" =
      {
        forceSSL = true;
        enableACME = true;
        root = "/var/www/replywithattachments";
        # Api
        locations."/api/" = {
          proxyPass = "http://localhost:8000/";
          extraConfig = ''
            proxy_pass_request_headers on;
            client_max_body_size 5M;
          '';

        };

        # RWA Add-in location
        locations."/" = {
          root = "/var/www/replywithattachments/webapp";
          extraConfig = ''
            try_files $uri /index.html;
          '';
        };

        # Web app location
        locations."/addin" = {
          extraConfig = ''
            try_files $uri;
          '';
        };

      };
  };

}

