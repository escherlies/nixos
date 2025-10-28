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

  environment.systemPackages = with pkgs; [
    gnome-tweaks

    gnomeExtensions.appindicator
    gnomeExtensions.clipboard-indicator

    # Emoji picker
    smile
    gnomeExtensions.smile-complementary-extension

    gnomeExtensions.tiling-shell
  ];
}
