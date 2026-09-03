{ pkgs, ... }:
{
  # Brave as a package only. The extensions, nativeMessagingHosts and
  # commandLineArgs that used to live here never applied, because
  # `programs.brave.enable` was false -- they are dropped rather than
  # left sitting inert.
  home.packages = [ pkgs.brave ];

  programs.chromium.enable = true;

  programs.chromium.extensions = [
    { id = "gejiddohjgogedgjnonbofjigllpkmbf"; } # 1Password Nightly – Password Manager
  ];
}
