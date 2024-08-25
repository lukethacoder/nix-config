{ inputs, lib, config, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";

  imports = [
    ./gitconfig.nix
    ./vscode.nix
  ];

  home = {
    username = "luke";
    homeDirectory = "/home/luke";
    packages = with pkgs; [
      _1password
      _1password-gui
    ];
  };

  home.file.".ssh/allowed_signers".text = "* ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAjRqXUdjUy7B8YzNn3mkWg5YqnaaW/Dm9abDAfhyUPz+ZnJCR9jJ7aX9kLx/Q7oRTkiJF/UEPpYnaZUmvGX+jgOTDgHJYDPBGNlSlRgbvAl7c12LYsFikhJsrgMXUASVteFvUEh2ULq/iQqT3Aq+z9jYcq52KeoQHn8onhfzHo6NWUab2e5fWvm80/qg3wjTd4oN6Wx3EsI2M8MFEW8kF78ZxPxK+jsmai4MwNDaVlrUhkdxUEiqxB22z5XaMonXm2z8xoJ0/ImjE1ur6v25lIV1Lfq2Wo4nEqsNLWY4s0A7yJ57RE4a5yevUh0gLh+ZEvNiMtuMNKtjWL0759IB4EFKtN4kzMjqKZfIrpPVKlVamU1w3bPBrPVJU/j07at5eNPMptGuDcGowdOaqo5Ppy+NFqi9hLRbCnC3JCXhaWemxeADhW954QFRTlh2lwrOxa4mQEtyaH6vMVPrywycGPxE11AodaXAHdSGITsjyHzLdkM+ip0Rhd3l52+Ts5w2Ik1X9+XwoTtO1gYrRj3p8tS3AfeKtuwtQT6tlx4HTwuE2eSWcWpIbNbs1EecqGC/iKabvgbsHD/SIaU4B51V7rgqZ9ajKiE5cTe+WcjKXFHk9Drk2UXCDVe+LnMg59THkABOxFo2EWSF7WlFb00Hpta1Gj759dOgf42mFyOXJfQ==";

  programs.ssh = {
    enable = true;
    # Host github.com
    #   IdentityAgent ~/.ssh/id_ed25519
    extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
    '';
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}