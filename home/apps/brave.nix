{ pkgs, ... }:
{
  programs.brave.enable = false;

  programs.brave.extensions = [
    # Lazily copy an extension from the store:
    # https://github.com/escherlies/chromium-extension-to-nix-expr

    { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
    { id = "lnjaiaapbakfhlbjenjkhffcdpoompki"; } # Catppuccin for Web File Explorer Icons
    { id = "gejiddohjgogedgjnonbofjigllpkmbf"; } # 1Password Nightly – Password Manager
    { id = "cdglnehniifkbagbbombnjghhcihifij"; } # Kagi Search
    { id = "edibdbjcniadpccecjdfdjjppcpchdlm"; } # I still don't care about cookies

  ];

  programs.brave.nativeMessagingHosts = [
    pkgs.kdePackages.plasma-browser-integration

  ];

  programs.brave.commandLineArgs = [
    "--disable-features=PasswordManagerOnboarding"
    "--disable-features=AutofillEnableAccountWalletStorage"
  ];

  programs.chromium.enable = true;

  programs.chromium.extensions = [
    { id = "gejiddohjgogedgjnonbofjigllpkmbf"; } # 1Password Nightly – Password Manager
  ];

}
