# Custom CA for Caddy's local HTTPS using the PKI app
#
# This module configures Caddy to use a pre-generated custom root CA
# for local HTTPS. The CA certificate and key are stored in the secrets
# directory (key encrypted with agenix).
#
# To generate the CA certificates:
#   ./scripts/generate-local-ca
#
{ config, pkgs, ... }:

let
  caCertPath = ../secrets/local_ca.crt;
  caKeyPath = ../secrets/local_ca.key.age;
  certStoreDir = "/var/lib/caddy/.local/share/caddy/certificates/local";
in
{
  # Decrypt the CA private key with agenix
  # Make it readable by the caddy service user
  age.secrets.local-ca-key = {
    file = caKeyPath;
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };

  # Configure Caddy to use our custom CA through the PKI app
  services.caddy = {
    enable = true;

    globalConfig = ''
      debug

      # Configure custom CA for local HTTPS
      pki {
        ca local {
          name "FFI Labs CA"
          root {
            format pem_file
            cert ${caCertPath}
            key ${config.age.secrets.local-ca-key.path}
          }
        }
      }
    '';

    # Test endpoint to verify custom CA is working
    virtualHosts."example.internal".extraConfig = ''
      tls internal
      respond "Using the 'local' CA configuration"
    '';
  };

  # Restart Caddy when CA certificate or key changes (content-based via Nix store hashes)
  systemd.services.caddy =
    let
      caHash = builtins.hashFile "sha256" caCertPath;
      keyHash = builtins.hashFile "sha256" caKeyPath;
      combinedHash = builtins.hashString "sha256" "${caHash}${keyHash}";
    in
    {
      restartTriggers = [ combinedHash ];
      environment.CADDY_CA_HASH = combinedHash;

      path = [ pkgs.openssl ];

      preStart = ''
        # Caddy's internal issuer stamps every leaf with the wall clock it sees
        # at issuance. A boot that comes up on a skewed RTC therefore mints a
        # certificate whose notBefore lies in the future, and every client
        # rejects it until that moment arrives — even after NTP has corrected
        # the clock, because the cert is cached in /var/lib/caddy. That is what
        # took ai.lan down on 2026-08-19: boot -2 started at 00:48 CEST while it
        # was really 23:00, so the leaf was valid from 00:48 the *next* day.
        # Wait for a synchronised clock (bounded — caddy is not on the boot
        # critical path, so a machine that is simply offline still comes up).
        for _attempt in $(seq 60); do
          if [ "$(timedatectl show --property NTPSynchronized --value)" = "yes" ]; then
            break
          fi
          echo "Waiting for NTP synchronisation before issuing certificates..."
          sleep 1
        done

        # Self-heal any leaf already minted against a skewed clock. Removing the
        # cert makes Caddy re-issue it from the intermediate on startup.
        for certFile in ${certStoreDir}/*/*.crt; do
          [ -e "$certFile" ] || continue
          notBefore=$(openssl x509 -in "$certFile" -noout -startdate | cut -d= -f2) || continue
          notBeforeEpoch=$(date -d "$notBefore" +%s) || continue
          if [ "$notBeforeEpoch" -gt "$(date +%s)" ]; then
            echo "Dropping not-yet-valid certificate $certFile (notBefore $notBefore)"
            rm -f "''${certFile%.crt}".*
          fi
        done

        STATUS_FILE="/var/lib/caddy/.local_ca_hash"

        if [ -f "$STATUS_FILE" ]; then
          PREV_HASH=$(cat "$STATUS_FILE")
        else
          PREV_HASH=""
        fi

        if [ "$CADDY_CA_HASH" != "$PREV_HASH" ]; then
          echo "Custom CA changed. Wiping Caddy PKI storage..."
          rm -rf /var/lib/caddy/.local/share/caddy/pki
          rm -rf /var/lib/caddy/.local/share/caddy/certificates/local
          echo "$CADDY_CA_HASH" > "$STATUS_FILE"
        else
          echo "Custom CA unchanged. Keeping existing certificates."
        fi
      '';
    };
}
