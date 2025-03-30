{ pkgs, inputs, config, configVars, ... }:
{
  nix = {
    # extraOptions = ''
    #   plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins
    # '';
    settings = {
      plugin-files = "${pkgs.nix-plugins}/lib/nix/plugins";
      extra-builtins-file = [
        "${inputs.self}/system.lib/extra-builtins.nix"
        ./extra-builtins.nix
      ];
    };
  };
}