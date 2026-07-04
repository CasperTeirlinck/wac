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
    # SVG/PDF → raster for snacks.image previews in nvim. Installed via
    # nixpkgs (not homebrew.brews) because brew's imagemagick is built
    # --without-pango and has no fonts, so its built-in SVG renderer fails
    # on text-heavy SVGs (Mermaid diagrams etc.) with `unable to read font ''`.
    # nixpkgs's build includes pangocairo + rsvg + fontconfig delegates.
    pkgs.imagemagick
    # `mmdc` — snacks.image's convert.mermaid recipe shells out to it to
    # turn ```mermaid code blocks into SVG, which imagemagick then rasters
    # for inline rendering in markdown buffers (Ghostty kitty graphics).
    pkgs.mermaid-cli
  ];

  # NOTE: mmdc needs a Chromium at runtime (PUPPETEER_EXECUTABLE_PATH) — the
  # nixpkgs build ships none. That env var is exported from the chezmoi
  # zshrc (home/.zshrc_darwin), since this repo's shell doesn't source
  # home-manager's hm-session-vars.sh.

  home.file = {
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = config-ext.git.userName;
      user.email = config-ext.git.userEmail;
      push.autoSetupRemote = true;
    };
  };

  programs.home-manager.enable = true;
}