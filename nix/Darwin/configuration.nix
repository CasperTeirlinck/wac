# Darwin configuration
# For available options see: https://daiderd.com/nix-darwin/manual/index.html

{ pkgs, ... }:
{
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

    system.defaults = {
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.ShowPathbar = true;
        finder.FXPreferredViewStyle = "clmv";

        dock.show-recents = false;
        dock.mru-spaces = false;
        dock.tilesize = 64;
        # dock.persistent-apps
    };
}