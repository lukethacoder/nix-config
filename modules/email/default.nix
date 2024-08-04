{ config, pkgs, lib, builtins, ... }:
let
  inherit (lib) mkIf types mkDefault mkOption mkMerge strings;
  inherit (builtins) head toString map tail;
in {
  options.email = {
    fromAddress = mkOption {
      description = "The 'from' address";
      type = types.str;
      default = "luke@example.com";
    };
    toAddress = mkOption {
      description = "The 'to' address";
      type = types.str;
      default = "luke@example.com";
    };
    smtpServer = mkOption {
      description = "The SMTP server address";
      type = types.str;
      default = "smtp.example.com";
    };
    smtpUsername = mkOption {
      description = "The SMTP username";
      type = types.str;
      default = "luke@example.com";
    };
    smtpPassword = mkOption {
      description = "Path to the secret containing SMTP password";
      type = types.str;
    };
  };
}