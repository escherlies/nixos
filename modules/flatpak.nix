{ ... }:
{
  # Declarative Flatpak management via nix-flatpak.
  # The flathub remote and the listed apps are reconciled on each rebuild;
  # apps not listed here are removed (see uninstallUnmanaged).
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      # MongoDB Compass — broken in nixpkgs (wrapGAppsHook failure), run via
      # Flatpak instead. See home/packages.nix.
      "com.mongodb.Compass"
    ];

    uninstallUnmanaged = false;
    update.onActivation = true;
  };
}
