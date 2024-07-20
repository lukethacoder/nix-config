{ lib, config, pkgs, vars, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "opslag";
    networkmanager.enable = false;
    useDHCP = true;
    interfaces.enp1s0.useDHCP = true;
  };

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