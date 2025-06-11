{ pkgs, ... }:
{
  programs.chromium.enable = true;

  programs.chromium.package = pkgs.brave;

  programs.chromium.extensions = [
    # Lazily copy an extension from the store:
    # https://github.com/escherlies/chromium-extension-to-nix-expr

    { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
    { id = "lnjaiaapbakfhlbjenjkhffcdpoompki"; } # Catppuccin for Web File Explorer Icons
    { id = "gejiddohjgogedgjnonbofjigllpkmbf"; } # 1Password Nightly – Password Manager
    { id = "cdglnehniifkbagbbombnjghhcihifij"; } # Kagi Search
    { id = "edibdbjcniadpccecjdfdjjppcpchdlm"; } # I still don't care about cookies

  ];

  programs.chromium.nativeMessagingHosts = [
    pkgs.kdePackages.plasma-browser-integration

  ];

}
