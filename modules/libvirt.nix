{
  pkgs,
  config,
  ...
}:
{
  # KVM/QEMU virtualization with virt-manager GUI
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; # TPM emulation (needed by some OSes)
      # OVMF (UEFI boot) is included by default in recent nixpkgs
    };
  };

  programs.virt-manager.enable = true;

  # Add the user to the libvirtd group
  users.users.enrico.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    spice-gtk # USB redirection & clipboard sharing with VMs
  ];
}
