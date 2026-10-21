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
    # Upstream has no setting for image thumbnail size (issue #508), so patch
    # the menu thumbnails from 1.5em to 7.5em.
    (gnomeExtensions.clipboard-indicator.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/stylesheet.css \
          --replace-fail "width:1.5em;" "width:7.5em; icon-size:7.5em;" \
          --replace-fail "height:1.5em;" "height:7.5em;"
      '';
    }))

    # Emoji picker
    smile
    gnomeExtensions.smile-complementary-extension

    gnomeExtensions.tiling-shell
    gnomeExtensions.gtile
    gnomeExtensions.hide-minimized

    kdePackages.elisa
  ];
}
