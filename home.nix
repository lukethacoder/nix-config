{ config, lib, pkgs, ... }:

{
  home.username = "luke";
  home.homeDirectory = "/home/luke";

  home.packages = with pkgs; [
    _1password
    _1password-gui
  ];

  home.file.".ssh/allowed_signers".text = "* ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAjRqXUdjUy7B8YzNn3mkWg5YqnaaW/Dm9abDAfhyUPz+ZnJCR9jJ7aX9kLx/Q7oRTkiJF/UEPpYnaZUmvGX+jgOTDgHJYDPBGNlSlRgbvAl7c12LYsFikhJsrgMXUASVteFvUEh2ULq/iQqT3Aq+z9jYcq52KeoQHn8onhfzHo6NWUab2e5fWvm80/qg3wjTd4oN6Wx3EsI2M8MFEW8kF78ZxPxK+jsmai4MwNDaVlrUhkdxUEiqxB22z5XaMonXm2z8xoJ0/ImjE1ur6v25lIV1Lfq2Wo4nEqsNLWY4s0A7yJ57RE4a5yevUh0gLh+ZEvNiMtuMNKtjWL0759IB4EFKtN4kzMjqKZfIrpPVKlVamU1w3bPBrPVJU/j07at5eNPMptGuDcGowdOaqo5Ppy+NFqi9hLRbCnC3JCXhaWemxeADhW954QFRTlh2lwrOxa4mQEtyaH6vMVPrywycGPxE11AodaXAHdSGITsjyHzLdkM+ip0Rhd3l52+Ts5w2Ik1X9+XwoTtO1gYrRj3p8tS3AfeKtuwtQT6tlx4HTwuE2eSWcWpIbNbs1EecqGC/iKabvgbsHD/SIaU4B51V7rgqZ9ajKiE5cTe+WcjKXFHk9Drk2UXCDVe+LnMg59THkABOxFo2EWSF7WlFb00Hpta1Gj759dOgf42mFyOXJfQ==";

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
          IdentityAgent ~/.1password/agent.sock
    '';
  };
  
  programs.git = {
    enable = true;
    userName = "lukethacoder";
    userEmail = "13529535+lukethacoder@users.noreply.github.com";

    aliases = {
      s = "status";
      p = "push";
      cm = "commit -m";
      a = "add";
    };

    extraConfig = {
      gpg.format = "ssh";
      gpg."ssh".program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      commit.gpgsign = true;
      user = {
        signingKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAjRqXUdjUy7B8YzNn3mkWg5YqnaaW/Dm9abDAfhyUPz+ZnJCR9jJ7aX9kLx/Q7oRTkiJF/UEPpYnaZUmvGX+jgOTDgHJYDPBGNlSlRgbvAl7c12LYsFikhJsrgMXUASVteFvUEh2ULq/iQqT3Aq+z9jYcq52KeoQHn8onhfzHo6NWUab2e5fWvm80/qg3wjTd4oN6Wx3EsI2M8MFEW8kF78ZxPxK+jsmai4MwNDaVlrUhkdxUEiqxB22z5XaMonXm2z8xoJ0/ImjE1ur6v25lIV1Lfq2Wo4nEqsNLWY4s0A7yJ57RE4a5yevUh0gLh+ZEvNiMtuMNKtjWL0759IB4EFKtN4kzMjqKZfIrpPVKlVamU1w3bPBrPVJU/j07at5eNPMptGuDcGowdOaqo5Ppy+NFqi9hLRbCnC3JCXhaWemxeADhW954QFRTlh2lwrOxa4mQEtyaH6vMVPrywycGPxE11AodaXAHdSGITsjyHzLdkM+ip0Rhd3l52+Ts5w2Ik1X9+XwoTtO1gYrRj3p8tS3AfeKtuwtQT6tlx4HTwuE2eSWcWpIbNbs1EecqGC/iKabvgbsHD/SIaU4B51V7rgqZ9ajKiE5cTe+WcjKXFHk9Drk2UXCDVe+LnMg59THkABOxFo2EWSF7WlFb00Hpta1Gj759dOgf42mFyOXJfQ==";
      };
      push.autoSetupRemote = true;
    };
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

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

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
