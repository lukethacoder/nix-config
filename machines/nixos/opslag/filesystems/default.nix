{ config, lib, pkgs, vars, ... }:
{
  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    gptfdisk
    xfsprogs
    parted
    mergerfs
    mergerfs-tools
  ];
  
  # fix odd MergerFS perms issue
  boot.initrd.systemd.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/89508460-a7c2-4869-9bf9-1cdbd22efe51";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5E3E-BAEA";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Data Disks
  fileSystems."/mnt/data1" = {
    device = "/dev/disk/by-partlabel/disk-data1-data";
    fsType = "xfs";
  };
  fileSystems."/mnt/data2" = {
    device = "/dev/disk/by-partlabel/disk-data2-data";
    fsType = "xfs";
  };
  fileSystems."/mnt/data3" = {
    device = "/dev/disk/by-partlabel/disk-data3-data";
    fsType = "xfs";
  };

  # Parity Disks
  fileSystems."/mnt/parity1" = {
    device = "/dev/disk/by-partlabel/disk-parity1-parity";
    fsType = "xfs";
  };

  # MergerFS
  fileSystems.${vars.mainArray} = {
    device = "/mnt/data*";
    options = [
      "defaults"
      "allow_other"
      "moveonenospc=1"
      "minfreespace=500G"
      "func.getattr=newest"
      "fsname=user"
      "uid=994"
      "gid=993"
      "umask=002"
      "x-mount.mkdir"
    ];
    fsType = "fuse.mergerfs";
  };

  swapDevices = [ ];
}