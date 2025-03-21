{ pkgs, inputs, config, configVars, ... }:
{
  nix = {
    settings = {
      plugin-files = "${pkgs.nix-plugins}/lib/nix/plugins";
      extra-builtins-file = [
        ../extra-builtins.nix
        "${inputs.self}/system.lib/extra-builtins.nix"
      ];
    }
  }
}