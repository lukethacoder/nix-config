{ config, pkgs, inputs, ... }:
{
  environment.systemPackages = [ 
    inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  environment.interactiveShellInit = ''
    if [ -r ${config.sops.templates."claude-code-env".path} ]; then
      set -a; . ${config.sops.templates."claude-code-env".path}; set +a
    fi
  '';

  system.activationScripts.claudeOnboarding = 
    let
      claudeJson = "/home/luke/.claude.json";
      group = config.users.users.luke.group;
    in ''
      if [ ! -e ${claudeJson} ]; then
        echo '{"hasCompletedOnboarding":true}' > ${claudeJson}
      else
        ${pkgs.jq}/bin/jq '.hasCompletedOnboarding = true' ${claudeJson} > ${claudeJson}.tmp && mv ${claudeJson}.tmp ${claudeJson}
      fi
      chown luke:${group} ${claudeJson}
    '';
}