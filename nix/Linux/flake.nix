{
    description = "Home Manager configuration";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        # tmux pinned to 3.5a. tmux 3.6/3.7 regressed handling of application
        # synchronized-output (DECSET 2026): under tmux on Windows Terminal (WSL)
        # the cursor flickers/jumps around when scrolling in nvim, because tmux no
        # longer keeps a pane's bracketed redraw atomic. 3.5a is fine (matches the
        # Mac). Confirmed by A/B test. Drop this pin (and the overlay below) once
        # upstream tmux fixes it. See dot_tmux.conf.tmpl for the full analysis.
        nixpkgs-tmux.url = "github:nixos/nixpkgs/nixos-25.05";
        nixgl.url = "github:nix-community/nixGL";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { nixpkgs, nixpkgs-tmux, home-manager, nixgl, ... }:
    let
        system = "x86_64-linux";
        tmuxPin = (import nixpkgs-tmux { inherit system; }).tmux;
        pkgs = import nixpkgs {
            inherit system;
            overlays = [ nixgl.overlay (final: prev: { tmux = tmuxPin; }) ];
        };
    in {
        homeConfigurations."casper" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home.nix ];

            # Optionally use extraSpecialArgs
            # to pass through arguments to home.nix
        };
    };
}