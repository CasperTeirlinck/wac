{ config, pkgs, lib, ... }:
let
  nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
    mkdir $out
    ln -s ${pkg}/* $out
    rm $out/bin
    mkdir $out/bin
    for bin in ${pkg}/bin/*; do
     wrapped_bin=$out/bin/$(basename $bin)
     echo "exec ${lib.getExe pkgs.nixgl.nixGLIntel} $bin \$@" > $wrapped_bin
     chmod +x $wrapped_bin
    done
  '';
in {
  home.username = "casper";
  home.homeDirectory = "/home/casper";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager release notes.
  home.stateVersion = "23.11";

  home.packages = [
    # Cannot use nixGL.auto.nixGLDefault because it is impure and not allowed with flakes,
    # if needed, figure something out by e.g. installing nixGL outside home-manager? With nix-channel? Or use --impure?
    # see: https://github.com/nix-community/nixGL/issues/114
    pkgs.nixgl.nixGLIntel

    # (nixGLWrap pkgs.wezterm)
    # (nixGLWrap pkgs.alacritty)
    pkgs.arandr
    pkgs.pasystray
    pkgs.cbatticon
    pkgs.gnome.nautilus
    pkgs.rofi
    pkgs.chezmoi
    pkgs.zsh
    pkgs.fzf
    pkgs.zoxide
    pkgs.eza
    pkgs.bat
    pkgs.trash-cli
    pkgs.tmux
    pkgs.neovim
    pkgs.atuin
    pkgs.neofetch
    pkgs.eyedropper
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  fonts.fontconfig.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.git = {
    enable = true;
    userName = "Casper Teirlinck";
    userEmail = "casperteirlinck@gmail.com";
  };

  # dconf = {
  #   enable = true;
  # };

  # gtk = {
  #   enable = true;
  #   iconTheme = {
  #     name = "Papirus-Dark";
  #     package = pkgs.papirus-icon-theme;
  #   };
  #   cursorTheme = {
  #     name = "Bibata-Modern-Classic";
  #   };
  #   # gtk2 = {
  #   #   extraConfig = ""
  #   #   # gtk-theme-name="Adwaita-dark"
  #   #   # gtk-icon-theme-name="Papirus"
  #   #   # gtk-cursor-theme-name="Bibata-Modern-Classic"
  #   #   # gtk-xft-antialias=1
  #   # };
  #   gtk3 = {
  #     extraConfig = {
  #       gtk-application-prefer-dark-theme = true;
  #     };
  #   };
  #   # theme = {
  #   #   name = "Catppuccin-Macchiato-Compact-Pink-Dark";
  #   #   package = pkgs.catppuccin-gtk.override {
  #   #     accents = [ "pink" ];
  #   #     size = "compact";
  #   #     tweaks = [ "rimless" "black" ];
  #   #     variant = "macchiato";
  #   #   };
  #   # };
  # };
  
  home.pointerCursor = 
    let 
      getFrom = url: hash: name: {
          gtk.enable = true;
          x11.enable = true;
          name = name;
          size = 24;
          package = 
            pkgs.runCommand "moveUp" {} ''
              mkdir -p $out/share/icons
              ln -s ${pkgs.fetchzip {
                url = url;
                hash = hash;
              }} $out/share/icons/${name}
          '';
        };
    in
      getFrom 
        "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.3/Bibata-Modern-Classic.tar.gz"
        "sha256-vn+91iKXWo++4bi3m9cmdRAXFMeAqLij+SXaSChedow="
        "Bibata-Modern-Classic";

  programs.home-manager.enable = true;

  targets.genericLinux.enable = true;
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };
}