{ inputs, lib, config, pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;

    userSettings = {
      buffer_font_family = "FiraCode Nerd Font";
      buffer_font_features = {
        # enable ligatures
        calt = true;
      };

      tab_size = 2;

      theme = {
        mode = "dark";
        light = "One Dark Pro";
        dark = "One Dark Pro";
      };

      ui_font_size = 14;
      buffer_font_size = 14;

      file_icons = true;
    };
    extensions = [
      "nix"
      "wakatime"
      "material-icon-theme"
      "one-dark-pro"
      "html"
      "svelte"
    ];
  };
}
