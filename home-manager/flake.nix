{
    description = "Home Manager configuration";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        # nixGL.url = "github:guibou/nixGL";
        nixGL = {
            url = "github:guibou/nixGL";
            flake = false;
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    # outputs = { nixpkgs, home-manager, ... } @ inputs:
    outputs = { nixpkgs, home-manager, nixGL, lib, ... }:
    let
        system = "x86_64-linux";
        # nixgl = inputs.nixgl;
        pkgs = nixpkgs.legacyPackages.${system};
        # pkgs = import nixpkgs {
        #     inherit system;
        #     overlays = [ nixgl.overlay ];
        # };
        nixgl = import nixGL {
            inherit pkgs;
        };
        nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
            mkdir $out
            ln -s ${pkg}/* $out
            rm $out/bin
            mkdir $out/bin
            for bin in ${pkg}/bin/*; do
            wrapped_bin=$out/bin/$(basename $bin)
            echo "exec ${lib.getExe nixgl.auto.nixGLDefault} $bin \$@" > $wrapped_bin
            chmod +x $wrapped_bin
            done
        '';
        
    in {
        homeConfigurations."casper" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [ ./home.nix ];

            # Optionally use extraSpecialArgs
            # to pass through arguments to home.nix
            extraSpecialArgs = {
                inherit nixgl;
            };
        };
    };
}