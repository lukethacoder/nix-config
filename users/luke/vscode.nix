{ inputs, lib, config, pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    userSettings = {
      "editor.fontFamily" = "'FiraCode Nerd Font', 'monospace', monospace";
      "editor.fontLigatures" = true;
      "editor.tabSize" = 2;
      "workbench.colorTheme" = "One Dark Pro";
      "workbench.iconTheme" = "material-icon-theme";
    };
    extensions = with pkgs.vscode-extensions; [
      wakatime.vscode-wakatime
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "Nix";
        publisher = "bbenoist";
        version = "1.0.1";
        sha256 = "sha256-qwxqOGublQeVP2qrLF94ndX/Be9oZOn+ZMCFX1yyoH0=";
      }
      {
        name = "Material-theme";
        publisher = "zhuangtongfa";
        version = "3.17.2";
        sha256 = "sha256-4s3I6FJUqvannOq6osPU79qExQJrgfP51wcr55yJ2Nc=";
      }
      {
        name = "material-icon-theme";
        publisher = "PKief";
        version = "5.8.0";
        sha256 = "sha256-L16dxKXmzK7pI5E4sZ6nBXRazBbg84rp2XY9RljkEuk=";
      }
    ];
  };
}