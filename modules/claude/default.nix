{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

  environment.systemPackages = [ pkgs.claude-code ];

  environment.interactiveShellInit = ''
    if [ -r ${config.sops.templates."claude-code-env".path} ]; then
      set -a; . ${config.sops.templates."claude-code-env".path}; set +a
    fi
  '';

}