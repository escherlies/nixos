# Custom CA for Caddy's local HTTPS using the PKI app
#
# This module configures Caddy to use a pre-generated custom root CA
# for local HTTPS. The CA certificate and key are stored in the secrets
# directory (key encrypted with agenix).
#
# To generate the CA certificates:
#   ./scripts/generate-local-ca
#
{ config, ... }:

let
  caCertPath = ../secrets/local_ca.crt;
  caKeyPath = ../secrets/local_ca.key.age;
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

      preStart = ''
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
