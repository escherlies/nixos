# Fan control for the MSI MAG B650 TOMAHAWK WIFI (desktop).
#
# The board's fan headers hang off a Nuvoton NCT6687D super-I/O chip at
# 0x4e. Nothing bound that chip before this module existed: the machine had
# no CPU or case fan RPM readings at all, and the fans ran on whatever curve
# the BIOS had programmed, with no way to change it from Linux.
#
# Two drivers claim this chip, and only one of them can set a fan speed:
#
#   nct6683 (in-tree)  — binds the chip, exposes pwm1..pwm8, and makes every
#                        one of them mode 0444. nct6683_pwm_is_visible()
#                        returns a writable mode only when the board's
#                        customer ID is MITAC; MSI gets read-only. The result
#                        is a thermometer, not a fan controller.
#   nct6687 (nixpkgs   — Fred78290's out-of-tree rewrite for exactly these
#    linuxPackages.      MSI boards. Same chip, writable pwm, plus working
#    nct6687d)           fan_min and per-channel pwm_enable.
#
# So this machine takes the out-of-tree one. Verified on the running board:
# under nct6683 all eight pwm files were 0444, which is why the choice is not
# a preference.
{
  config,
  pkgs,
  ...
}:

{
  boot.extraModulePackages = [ config.boot.kernelPackages.nct6687d ];
  boot.kernelModules = [ "nct6687" ];

  # Both drivers probe the same I/O ports, and whichever lands first owns the
  # chip. If nct6683 wins the race the pwm files come back read-only and fan
  # control silently does nothing — the sensors still read fine, which makes
  # it look like it worked. Keep it out of the kernel entirely.
  boot.blacklistedKernelModules = [ "nct6683" ];

  # Daemon reads the hwmon tree and drives the pwm channels; the GUI is the
  # curve editor. CoolerControl matches devices by name and firmware UID
  # rather than by /sys/class/hwmon/hwmonN index, which matters here because
  # that index is assigned in probe order and moves between boots — the
  # nct6687 chip came up as hwmon8 when probed by hand and will not be hwmon8
  # at boot. A fancontrol(8) config, which hardcodes those paths, would point
  # at the wrong chip after a reboot.
  programs.coolercontrol.enable = true;

  # `sensors` for checking the same values from a shell or over SSH, without
  # a session on the machine.
  environment.systemPackages = [ pkgs.lm_sensors ];
}
