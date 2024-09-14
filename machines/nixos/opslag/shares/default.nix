{ users, pkgs, config, lib, ... }:
let 
  smb = {
    share_list = {
      Media = { path = "/mnt/user/Media"; };
    };
    share_params = {
      "browsable" = "yes";
      "writeable" = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
      "valid users" = "share";
      "force user" = "share";
    };
  };
  smb_shares = builtins.mapAttrs (name: value: value // smb.share_params) smb.share_list;
in
{
  # make shares visible for windows 10 clients
  services.samba-wsdd.enable = true;

  users = {
    groups.share = {
      gid = 993;
    };
    users.share = {
      uid = 994;
      isSystemUser = true;
      group = "share";
    };
  };

  environment.systemPackages = [ config.services.samba.package ];

  users.users.luke.extraGroups = [ "share" ];

  systemd.tmpfiles.rules = map (x: "d ${x.path} 0775 share share - - ") (lib.attrValues smb.share_list) ++ [ "d /mnt/user 0775 share share - -" ];

  system.activationScripts.samba_user_create = ''
    smb_password=$(cat "${config.sops.secrets.samba_password.path}")
    echo -e "$smb_password\n$smb_password\n" | /run/current-system/sw/bin/smbpasswd -a -s share
  '';

  networking.firewall = {
    allowedTCPPorts = [ 5357 ];
    allowedUDPPorts = [ 3702 ];
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    invalidUsers = [
      "root"
    ];
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = ${config.networking.hostName}
      netbios name = ${config.networking.hostName}
      security = user
      hosts allow = 192.168.0.0/16 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
      passdb backend = tdbsam
    '';
    shares = smb_shares;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
  };

  # not ideal, but doesn't seem to let windows have write access without 0777 :(
  system.activationScripts.giveShareUserAccessToFolders = 
    let
      user = config.users.users.share.name;
      group = config.users.users.share.group;
    in
      ''
        chown -R ${user}:${group} /mnt/user/Media
        chmod -R 0777 /mnt/user/Media
      '';
}