{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      fira-code-nerdfont
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "FiraCode Nerd Font" ];
      };
    };
  };
}