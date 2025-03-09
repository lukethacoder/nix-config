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

  # MergerFS
  fileSystems.${vars.mainArray} = {
    depends = [
      "/mnt/data1"
      "/mnt/data2"
      "/mnt/data3"
    ];
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

  # Parity Disks
  fileSystems."/mnt/parity1" = {
    depends = [
      vars.mainArray
    ];
    device = "/dev/disk/by-partlabel/disk-parity1-parity";
    fsType = "xfs";
  };

  swapDevices = [ ];

  services.snapraid = {
    enable = true;
    # extraConfig = ''
    #   nohidden
    #   blocksize 256
    #   hashsize 16
    #   autosave 500
    #   pool /pool
    # '';
    parityFiles = [
      # Defines the file(s) to use as parity storage
      # It must NOT be in a data disk
      # Format: "FILE_PATH"
      "/mnt/parity1/snapraid.parity"
    ];
    contentFiles = [
      # Defines the files to use as content list.
      # You can use multiple specification to store more copies.
      # You must have at least one copy for each parity file plus one. Some more don't hurt.
      # They can be in the disks used for data, parity or boot,
      # but each file must be in a different disk.
      # Format: "content FILE_PATH"
      "/persist/snapraid/snapraid.content"
      "/mnt/parity1/.snapraid.content"
      "/mnt/data1/.snapraid.content"
      "/mnt/data2/.snapraid.content"
      "/mnt/data3/.snapraid.content"
    ];
    dataDisks = {
      # Defines the data disks to use
      # The order is relevant for parity, do not change it
      # Format: "DISK_NAME DISK_MOUNT_POINT"
      d01 = "/mnt/data1/";
      d02 = "/mnt/data2/";
      d03 = "/mnt/data3/";
    };
    # touchBeforeSync = true; # Whether `snapraid touch` should be run before `snapraid sync`
    sync.interval = "03:00";
    scrub.interval = "weekly";
    # scrub.plan = 8 # Percent of the array that should be checked by `snapraid scrub`.
    # scrub.olderThan = 10; # Number of days since data was last scrubbed before it can be scrubbed again.
    exclude = [
      # Define files and directories to exclude
      # Remember that all the paths are relative at the mount points
      # Format: "FILE"
      # Format: "DIR/"
      # Format: "/PATH/FILE"
      # Format: "PATH/DIR/"
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "*.!sync"
      ".DS_Store"
      "._.DS_Store"
      "/Media/TV/"
      "/Media/Movies/"
      "/Photos/immich/thumbs/"
      ".Thumbs.db"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
    ];
  };

  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -n standby,q";
    notifications = {
      wall = {
        enable = true;
      };
      mail = {
        enable = true;
        sender = builtins.readFile config.sops.secrets.email_address.path;
        recipient = builtins.readFile config.sops.secrets.email_address.path;
      };
    };
  };

  # Give user access to: 
  # - MergerFS mount
  # - boot drive snapraid dir
  # - parity disk(s)
  system.activationScripts.giveUserAccessToDataDisk = 
    let
      user = config.users.users.luke.name;
      group = config.users.users.luke.group;
    in
      ''
        chown -R ${user}:${group} ${vars.mainArray}
        chown -R ${user}:${group} /mnt/parity1
        chown -R ${user}:${group} /persist/snapraid
      '';
}