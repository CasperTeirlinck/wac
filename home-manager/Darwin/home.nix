{ config, pkgs, ... }: {
  home.username = "casper";
  home.homeDirectory = "/Users/casper";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager release notes.
  home.stateVersion = "23.11";

  home.packages = [
  ];

  home.file = {
  };

  programs.home-manager.enable = true;
}