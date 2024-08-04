{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  environment.systemPackages = with pkgs; [
    parted
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/89508460-a7c2-4869-9bf9-1cdbd22efe51";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5E3E-BAEA";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];
  
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s20f0u8u2c2.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;


  # Data Disks
  # fileSystems."/mnt/data1" = {
  #   device = "/dev/disk/by-partlabel/disk-data1-data";
  #   fsType = "xfs";
  # };
  # fileSystems."/mnt/data2" = {
  #   device = "/dev/disk/by-partlabel/disk-data2-data";
  #   fsType = "xfs";
  # };
  # fileSystems."/mnt/data3" = {
  #   device = "/dev/disk/by-partlabel/disk-data3-data";
  #   fsType = "xfs";
  # };

  # # Parity Disks
  # fileSystems."/mnt/parity1" = {
  #   device = "/dev/disk/by-partlabel/disk-parity1-parity";
  #   fsType = "xfs";
  # };

  # MergerFS
  # fileSystems.${vars.mainArray} = {
  #   device = "/mnt/data*";
  #   options = [
  #     "defaults"
  #     "allow_other"
  #     "moveonenospc=1"
  #     "minfreespace=500G"
  #     "func.getattr=newest"
  #     "fsname=user"
  #     "uid=994"
  #     "gid=993"
  #     "umask=002"
  #     "x-mount.mkdir"
  #   ];
  #   fsType = "fuse.mergerfs";
  # };
}