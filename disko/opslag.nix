{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # "/dev/nvme0n1";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S466NX0K701415F";
        content = {
          type = "gpt";
          partitions = {
            # boot / BIOS
            bios = {
              size = "1M";
              type = "EF02";
            };
            efi = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      # DO NOT ENABLE IF YOU HAVE DATA ON YOUR HDDs
      # running this may format and wipe your disks
      # data1 = {
      #   type = "disk";
      #   device = "/dev/sda";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       data = {
      #         type = "8300";
      #         content = {
      #           type = "filesystem";
      #           format = "xfs";
      #           mountpoint = "/data1";
      #         };
      #       };
      #     };
      #   };
      # };

      # data2 = {
      #   type = "disk";
      #   device = "/dev/sdb";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       data = {
      #         type = "8300";
      #         content = {
      #           type = "filesystem";
      #           format = "xfs";
      #           mountpoint = "/data2";
      #         };
      #       };
      #     };
      #   };
      # };

      # data3 = {
      #   type = "disk";
      #   device = "/dev/sdc";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       data = {
      #         type = "8300";
      #         content = {
      #           type = "filesystem";
      #           format = "xfs";
      #           mountpoint = "/data3";
      #         };
      #       };
      #     };
      #   };
      # };

      # parity1 = {
      #   type = "disk";
      #   device = "/dev/sdd";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       parity = {
      #         type = "8300";
      #         content = {
      #           type = "filesystem";
      #           format = "xfs";
      #           mountpoint = "/parity1";
      #         };
      #       };
      #     };
      #   };
      # };
    };
  };

}