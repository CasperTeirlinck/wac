{ config, pkgs, ... }:
let
  # Need to import with absolute path (and impure flag) because this config is in gitignore.
  config-ext = import "${builtins.getEnv "PWD"}/config/config.nix";
in {
  home.username = config-ext.home.username;
  home.homeDirectory = config-ext.home.homeDirectory;

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager release notes.
  home.stateVersion = "23.11";

  home.packages = [
  ];

  home.file = {
  };

  programs.git = {
    enable = true;
    userName = config-ext.git.userName;
    userEmail = config-ext.git.userEmail;
  };

  programs.home-manager.enable = true;
}