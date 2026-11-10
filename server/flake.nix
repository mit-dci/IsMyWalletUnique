{
  description = "HTTP server for serving latest wallet fingerprint vectors";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmtFor =
        pkgs:
        (treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.rustfmt.enable = true;
        }).config.build;
    in
    {
      packages = forAllSystems (pkgs: {
        server = pkgs.rustPlatform.buildRustPackage {
          pname = "server";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          meta.mainProgram = "server";
        };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.server;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.server ];
          packages = [
            pkgs.clippy
            pkgs.rustfmt
          ];
        };
      });

      formatter = forAllSystems (pkgs: (treefmtFor pkgs).wrapper);

      checks = forAllSystems (pkgs: {
        formatting = (treefmtFor pkgs).check self;
      });
    };
}
