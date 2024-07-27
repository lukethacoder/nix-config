{ inputs, config, lib, vars, pkgs, ... }:
{
  imports = [
    ./snapraid.nix
  ];

  # services.zfs = {
  #   autoScrub.enable = true;
  #   zed.settings = {
  #     ZED_DEBUG_LOG = "/tmp/zed.debug.log";
  #     ZED_EMAIL_ADDR = [ "server_announcements@mailbox.org" ];
  #     ZED_EMAIL_PROG = "/run/current-system/sw/bin/notify";
  #     ZED_EMAIL_OPTS = "-t '@SUBJECT@' -m";

  #     ZED_NOTIFY_INTERVAL_SECS = 3600;
  #     ZED_NOTIFY_VERBOSE = true;

  #     ZED_USE_ENCLOSURE_LEDS = true;
  #     ZED_SCRUB_AFTER_RESILVER = true;
  #   };
  #   zed.enableMail = false;
  # };

  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    gptfdisk
    xfsprogs
    parted
    snapraid
    mergerfs
    mergerfs-tools
  ];

  # This fixes the weird mergerfs permissions issue
  boot.initrd.systemd.enable = true;

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod" 
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    
    loader = {
      efi = {
        canTouchEfiVariables = (if cfg.removableEfi then false else true);
        efiSysMountPoint = "/boot/esp";
      };
      generationsDir.copyKernels = true;
      # grub = {
      #   enable = true;
      #   #devices = (map (diskName: cfg.devNodes + diskName) cfg.bootDevices);
      #   device = "nodev";
      #   efiInstallAsRemovable = cfg.removableEfi;
      #   copyKernels = true;
      #   efiSupport = true;
      #   zfsSupport = true;
      #   extraInstallCommands = (toString (map (diskName: ''
      #     set -x
      #     ${pkgs.coreutils-full}/bin/cp -r ${config.boot.loader.efi.efiSysMountPoint}/EFI /boot/esp
      #     set +x
      #   '') (tail cfg.bootDevices)));
      # };
    };
  };

  # boot.initrd.systemd.services.rollback = {
  #   description = "Rollback ZFS datasets to a pristine state";
  #   wantedBy = [
  #     "initrd.target"
  #   ]; 
  #   after = [
  #     "zfs-import-zroot.service"
  #   ];
  #   before = [ 
  #     "sysroot.mount"
  #   ];
  #   path = with pkgs; [
  #     zfs
  #   ];
  #   unitConfig.DefaultDependencies = "no";
  #   serviceConfig.Type = "oneshot";
  #   script = ''
  #     zfs rollback -r nixos/empty@start
  #   '';
  # };
  
  fileSystems."/" = lib.mkForce {
    device = "nixos/empty";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "vfat";
  };


  # fileSystems."/nix" = {
  #   device = "nixos/nix";
  #   fsType = "zfs";
  #   neededForBoot = true;
  # };

  # fileSystems."/etc/nixos" = {
  #   device = "nixos/config";
  #   fsType = "zfs";
  #   neededForBoot = true;
  # };

  fileSystems."/home" = {
    device = "nixos/home";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/persist" = {
    device = "nixos/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/var/log" = {
    device = "nixos/var/log";
    fsType = "zfs";
  };

  fileSystems."/var/lib/containers" = {
    device = "/dev/zvol/docker";
    fsType = "ext4";
  };

  # fileSystems.${vars.cacheArray} = {
  #   device = "cache";
  #   fsType = "zfs";
  # };

  fileSystems."/mnt/data1" = {
    device = "/dev/disk/by-label/data1";
    fsType = "xfs";
  };

  fileSystems."/mnt/data2" = {
    device = "/dev/disk/by-label/data2";
    fsType = "xfs";
  };

  fileSystems."/mnt/data3" = {
    device = "/dev/disk/by-label/data3";
    fsType = "xfs";
  };

  fileSystems."/mnt/parity1" = {
    device = "/dev/disk/by-label/parity1";
    fsType = "xfs";
  };

  # fileSystems.${vars.slowArray} = {
  #   device = "/mnt/data*";
  #   options = [
  #     "defaults"
  #     "allow_other"
  #     "moveonenospc=1"
  #     "minfreespace=1000G"
  #     "func.getattr=newest"
  #     "fsname=mergerfs_slow"
  #     "uid=994"
  #     "gid=993"
  #     "umask=002"
  #     "x-mount.mkdir"
  #   ];
  #   fsType = "fuse.mergerfs";
  # };

  fileSystems.${vars.mainArray} = {
    device = "/mnt/data*";
    options = [
      "defaults"
      "allow_other"
      "moveonenospc=1"
      "minfreespace=1000G"
      "func.getattr=newest"
      "fsname=mergerfs_slow"
      "uid=994"
      "gid=993"
      "umask=002"
      "x-mount.mkdir"
    ];
    fsType = "fuse.mergerfs";
  };

  # fileSystems.${vars.mainArray} = {
  #   device = "${vars.cacheArray}:${vars.slowArray}";
  #   options = [
  #     "category.create=epff"
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
  
  
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -n standby,q";
    notifications = {
      wall = {
        enable = true;
      };
      mail = {
        enable = true;
        sender = "dev+from@lukesecomb.digital";
        recipient = "dev+to@lukesecomb.digital";
      };
    };
  };
}
