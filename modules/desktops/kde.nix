{ pkgs, ... }:
{
  # Use wayland
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.enable = true;

  # Plasma 6
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
    kate
  ];

}
