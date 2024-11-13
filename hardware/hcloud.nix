{ modulesPath, ... }:
{
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "vmw_pvscsi"
    "xen_blkfront"
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
    "ext4"
  ];

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

}
