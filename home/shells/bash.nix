{ osConfig, ... }:
let
  extraPaths = import ./paths.nix;
in
{
  programs.bash = {
    enable = true;

    profileExtra = ''
      # Add shared extra paths
      ${builtins.concatStringsSep "\n" (map (p: ''export PATH="${p}:$PATH"'') extraPaths)}

      # Load user environment variables from agenix secrets
      if [ -f "${osConfig.age.secrets.user-env.path}" ]; then
        while IFS='=' read -r key value; do
          [[ "$key" =~ ^[[:space:]]*# ]] && continue
          [[ -z "$key" ]] && continue
          export "$key=$value"
        done < "${osConfig.age.secrets.user-env.path}"
      fi
    '';
  };
}
