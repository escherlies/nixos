{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['scale-monitor-framebuffer', 'xwayland-native-scaling']
  '';

  environment.systemPackages = with pkgs; [
    gnome-tweaks

    gnomeExtensions.emoji-copy
    gnomeExtensions.clipboard-history
    gnomeExtensions.appindicator
  ];
}
