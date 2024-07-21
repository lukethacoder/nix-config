{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S466NX0K701415F";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/esp";
              };
            };
            bpool = {
              size = "4G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };
            rpool = {
              end = "-1M";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
            bios = {
              size = "100%";
              type = "EF02";
            };
          };
        };
      };
    };

    data1 = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          data = {
            type = "8300";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/data1";
            };
          };
        };
      };
    };

    data2 = {
      type = "disk";
      device = "/dev/sdb";
      content = {
        type = "gpt";
        partitions = {
          data = {
            type = "8300";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/data2";
            };
          };
        };
      };
    };

    data3 = {
      type = "disk";
      device = "/dev/sdc";
      content = {
        type = "gpt";
        partitions = {
          data = {
            type = "8300";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/data3";
            };
          };
        };
      };
    };

    parity1 = {
      type = "disk";
      device = "/dev/sdd";
      content = {
        type = "gpt";
        partitions = {
          parity = {
            type = "8300";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/parity1";
            };
          };
        };
      };
    };
  };

  zpool = {
    bpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
        compatibility = "grub2";
      };
      rootFsOptions = {
        acltype = "posixacl";
        canmount = "off";
        compression = "lz4";
        devices = "off";
        normalization = "formD";
        relatime = "on";
        xattr = "sa";
        "com.sun:auto-snapshot" = "false";
      };
      mountpoint = "/boot";
      datasets = {
        nixos = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/root" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/boot";
        };
      };
    };

    rpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        canmount = "off";
        compression = "zstd";
        dnodesize = "auto";
        normalization = "formD";
        relatime = "on";
        xattr = "sa";
        "com.sun:auto-snapshot" = "false";
      };
      mountpoint = "/";

      datasets = {
        nixos = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/var" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/empty" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/";
          postCreateHook = "zfs snapshot rpool/nixos/empty@start";
        };
        "nixos/home" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/home";
        };
        "nixos/var/log" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var/log";
        };
        "nixos/var/lib" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/config" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/etc/nixos";
        };
        "nixos/persist" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/persist";
        };
        "nixos/nix" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/nix";
        };
        docker = {
          type = "zfs_volume";
          size = "50G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/var/lib/containers";
          };
        };
      };
    };
  };
}