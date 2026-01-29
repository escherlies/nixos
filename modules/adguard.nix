{ ... }:

{
  services.adguardhome = {
    mutableSettings = false;
    enable = true;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      users = [
        {
          name = "admin";
          password = "$2b$05$Cu8NwH2KTlr.DHGgGJHQDOBZxPh3Aodf6uHCQTehxEwekTELD.Gf2";
        }
      ];

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        # Upstream DNS servers
        upstream_dns = [
          "https://dns.mullvad.net/dns-query"
          "tls://dns.mullvad.net"
          "https://dns.sb/dns-query"
          "https://doh.dns.sb/dns-query"
          "tls://dot.sb"
          "https://dns.digitale-gesellschaft.ch/dns-query"
          "tls://dns.digitale-gesellschaft.ch"
          "https://protective.joindns4.eu/dns-query"
          "tls://protective.joindns4.eu"
          "tls://dns.quad9.net"
          "https://dns.quad9.net/dns-query"
        ];

        # Enable DNS-over-HTTPS/TLS support
        bootstrap_dns = [ ]; # Use default values
      };

      # Filtering settings
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];

      filtering = {
        rewrites = [
          {
            enabled = true;
            domain = "hoa.gg";
            answer = "192.168.178.134";
          }
        ];
      };

      # Query logging
      querylog = {
        enabled = true;
        interval = "2160h"; # 90 days
        size_memory = 1000;
      };

      # Statistics
      statistics = {
        enabled = true;
        interval = "24h";
      };
    };
  };

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS
      3000 # AdGuard Home Web UI
    ];
    allowedUDPPorts = [
      53 # DNS
    ];
  };
}
