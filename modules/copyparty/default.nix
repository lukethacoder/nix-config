{ pkgs, ... }:
{
  nixpkgs.overlays = [ copyparty.overlays.default ];

  environment.systemPackages = [ pkgs.copyparty ];
  services.copyparty = {
    enable = true;
    user = "copyparty";
    group = "copyparty";
    settings = {
      i = "0.0.0.0";
      p = [ 3210 3211 ];
    };

    accounts = {
      test = {
        passwordFile = "${config.sops.secrets."adguard/password".path}";
      };
    };

    groups = {
      g1 = { "test" };
    };

    volumes = {
      "/" = {
        path = "";
        access = {
          # everyone gets read access
          r = "*";
          # users get read-write
          rw = [ "test" ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          fk = 4;
          scan = 60;
          e2d = true;
          d2t = true;
          # skip hashing file contents if path matches `*.iso`
          nohash = "\.iso$";
        };
      }
    };

    openFilesLimit = 8192;
  };


};