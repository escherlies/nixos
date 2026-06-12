{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Set default stop job timeout
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['scale-monitor-framebuffer', 'xwayland-native-scaling']
  '';

  environment.gnome.excludePackages = with pkgs; [
    gnome-music
    gnome-console
  ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks

    # Adds "Copy Path" to the Nautilus (Files) right-click menu.
    # nautilus-python provides the loader; the package below drops the
    # extension into share/nautilus-python/extensions (linked via the GNOME
    # module's environment.pathsToLink).
    nautilus-python
    (callPackage ./nautilus-copypath { })

    gnomeExtensions.appindicator
    gnomeExtensions.clipboard-indicator

    # Emoji picker
    smile
    gnomeExtensions.smile-complementary-extension

    gnomeExtensions.tiling-shell
    gnomeExtensions.gtile
    gnomeExtensions.hide-minimized

    kdePackages.elisa
  ];
}
