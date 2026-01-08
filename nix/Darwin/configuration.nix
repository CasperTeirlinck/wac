# Darwin configuration
# For available options see: https://daiderd.com/nix-darwin/manual/index.html

{ config, pkgs, ... }:
let
    # Need to import with absolute path (and impure flag) because this config is in gitignore.
    config-ext = import "${builtins.getEnv "PWD"}/config/config.nix";
in {
    system.stateVersion = 5;

    users.users.casper.home = "/Users/casper";
    # Auto upgrade nix package and the daemon service.
    services.nix-daemon.enable = true;
    nix.useDaemon = true;
    # Enable experimental nix command and flakes.
    nix.settings.experimental-features = "nix-command flakes";
    # Create /etc/bashrc that loads the nix-darwin environment.
    programs.zsh.enable = true;
    nixpkgs.hostPlatform = "aarch64-darwin";
    # Add ability to used TouchID for sudo authentication
    security.pam.enableSudoTouchIdAuth = true;
    nix.configureBuildUsers = true;
    # This does not install Homebrew itself
    homebrew.enable = true;

    homebrew.casks = [
        "visual-studio-code"
        "brave-browser"
        "keepassxc"
        "obsidian"
        "iterm2"
        "rancher"
        "tunnelblick"
        "dbeaver-community"
        "ghostty"
        "chatbox"
        # "karabiner-elements" # not used to do actual key mappings
    ];
    homebrew.brews = [
        # wac
        "chezmoi"
        "mise"
        # shell
        "tmux"
        "fzf"
        "eza"
        "zoxide"
        "atuin"
        # tooling
        "yq"
        "ruff"
        "neovim"
        "poetry"
        "uv"
        "pre-commit"
        "cruft"
        "cookiecutter"
        "k9s"
        "awscli"
        "saml2aws"
        "krew"
        "zsh-autosuggestions"
        "localstack/tap/localstack-cli"
        "granted"
        "starship"
        "dive"
        "rustscan"
        "bruno"
        "fd"
        "zellij"
        "shellcheck"
        # system utils
        # "scroll-reverser"
    ];
    homebrew.taps = [
        "common-fate/granted"
    ];

    fonts.packages = [
        (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];

    # TODO: figure out how to do this all in nix, for now key remaps are handeled by Karabiner-Elements
    # NOTE: this is tested with the U.S. keyboard layout on AZERTY Macbook Pro keyboard
    
    # # For now, do it manually in the Settings (can set modifier key mappings per keyboard in settings)
    # # These settings go hand-in-hand with the Library/KeyBindings.dict!
    # # things to still do manually are:
    # # - Need to remove the default control-left/right shortcuts in mission control in Settings -> Keyboard -> Keyboard Shortcuts -> Mission Control -> Mission Control

    # # To have proper keyboard mappings that don't handicap me:
    # # 1. Swap Ctrl with Cmd keys: so that on external kb shortcuts like copy-paste work properly
    # # 2. Swap fn (glowbe) with cmd so that ctrl commands work properly on the macbook keyboard layout
    # system.keyboard.enableKeyMapping = true;
    # system.keyboard.remapCapsLockToEscape = true;
    # system.keyboard.userKeyMapping = [
    #     # How to find the key ids:
    #     # 1. Open Karabiner-EventViewer and press the key you want
    #     # 2. Get the usage hex value
    #     # 3. Bitwise OR it with 0x700000000
    #     # 4. Convert the result to decimal
    #     {
    #         HIDKeyboardModifierMappingSrc = 30064771172; # §
    #         HIDKeyboardModifierMappingDst = 30064771125; # `
    #     }
    # ];

    system.defaults = {
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.ShowPathbar = true;
        finder.FXPreferredViewStyle = "clmv";

        dock.autohide = false;
        dock.show-recents = false;
        dock.mru-spaces = false;
        dock.tilesize = 40;
        dock.persistent-apps = [
            "/Applications/iTerm.app"
            "/Applications/KeePassXC.app"
            "/Applications/Brave Browser.app"
            "/Applications/Obsidian.app"
        ] ++ config-ext.dock-extra-apps;
        dock.persistent-others = [];

        NSGlobalDomain."com.apple.keyboard.fnState" = true;
        NSGlobalDomain.KeyRepeat = 2; # 120, 90, 60, 30, 12, 6, 2
        NSGlobalDomain.InitialKeyRepeat = 15; # 120, 94, 68, 35, 25, 15
        WindowManager.EnableStandardClickToShowDesktop = false;
    };
}
