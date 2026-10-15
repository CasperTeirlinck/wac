{
    description = "Home Manager configuration";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        darwin.url = "github:lnl7/nix-darwin";
        darwin.inputs.nixpkgs.follows = "nixpkgs";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Fork with nested-session (stack) support; PR-able to raine/workmux.
        workmux.url = "github:CasperTeirlinck/workmux/nested-sessions";
    };

    outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: 
        let 
            hostname = "M604237";
        in {
        darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
                ./configuration.nix
                home-manager.darwinModules.home-manager {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.casper = import ./home.nix;
                    home-manager.extraSpecialArgs = { inherit inputs; };
                }
            ];
        };
    };
}