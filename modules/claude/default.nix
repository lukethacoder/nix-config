{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  environment.systemPackages = [ pkgs.claude-code ];

  sops.secrets."claude/oauth_token" = {
    owner = "luke";
    mode = "0400";
  };

  environment.interactiveShellInit = ''
    if [ -r ${config.sops.templates."claude-code.env"}.path} ]; then
      set -a; . ${config.sops.templates."claude-code.env".path}; set +a
    fi
  '';

}