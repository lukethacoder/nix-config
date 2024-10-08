{ config, pkgs, ... }:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      # extraPackages = [ pkgs.zfs ];
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
    oci-containers = {
      backend = "podman";
    };
  };
  networking.firewall.interfaces.podman0.allowedUDPPorts = [ 53 ];

  environment.systemPackages = with pkgs; [
    podman-tui
    # podman-compose
  ];
}