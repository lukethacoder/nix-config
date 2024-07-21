{ lib, config, pkgs, vars, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  imports = [
    ./filesystems
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        # efiInstallAsRemovable = true;
        fsIdentifier = "label";
        devices = [ "nodev" ];
      };
    };
    initrd.availableKernelModules = [
      "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sr_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    zfs.forceImportRoot = true;
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    opengl = {
      enable = true;
      driSupport = true;
    };
  };
  
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "nvme-Samsung_SSD_970_EVO_500GB_S466NX0K701415F" ];
      immutable = false;
      availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];

      removableEfi = true;
      kernelParams = [
        "pcie_aspm=force"
        "consoleblank=60"
        "acpi_enforce_resources=lax"
      ];
      sshUnlock = {
        enable = false;
        authorizedKeys = [ ];
      };
    };
    networking = {
      hostName = "opslag";
      timeZone = vars.timeZone;
      hostId = "0730ae51";
    };
  };

  networking = {
    hostName = "opslag";
    networkmanager.enable = false;
    useDHCP = true;
    interfaces.enp1s0.useDHCP = true;
    # interfaces.eno1.useDHCP = lib.mkDefault true;
    # interfaces.eno2.useDHCP = lib.mkDefault true;
    # interfaces.enp0s20f0u8u2c2.useDHCP = lib.mkDefault true;
  };

  # TODO: configure HDD Fan Control https://github.com/desbma/hddfancontrol
  # services.hddfancontrol = {
  #   enable = true;
  #   disks = [
  #     "/dev/disk/by-label/Data1"
  #     "/dev/disk/by-label/Data2"
  #     "/dev/disk/by-label/Data3"
  #     "/dev/disk/by-label/Parity1"
  #   ];
  #   pwmPaths = [
  #     "/sys/class/hwmon/hwmon1/device/pwm2"
  #   ];
  #   extraArgs = [
  #     "--pwm-start-value=100"
  #     "--pwm-stop-value=50"
  #     "--smartctl"
  #     "-i 30"
  #     "--spin-down-time=900"
  #   ];
  # };

  # internationalisation
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    enable = true;
    xkb = {
      layout = "au";
    };
    desktopManager.gnome.enable = true;
    displayManager = {
      gdm = {
        enable = true;
        autoSuspend = false;
      };
      setupCommands = ''
        ${pkgs.xorg.xrandr}/bin/xrandr --output DP-1 --off DP-2 --off --output HDMI-1 --mode 1920x1080 --pos 0x0 --rota>      '';
    };
  };
}