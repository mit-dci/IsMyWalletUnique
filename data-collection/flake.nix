{
  description = "Scan a Bitcoin Core data directory into a DuckDB file of wallet fingerprints";

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
        scan = pkgs.rustPlatform.buildRustPackage {
          pname = "scan";
          version = "0.1.0";
          src = ./.;
          cargoLock = {
            lockFile = ./Cargo.lock;
            allowBuiltinFetchGit = true;
          };
          # libbitcoinkernel-sys runs cmake from its build.rs, not at the top level.
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.rustPlatform.bindgenHook
          ];
          dontUseCmakeConfigure = true;
          # Boost 1.91 multi_index rejects Bitcoin Core's mempool indices.
          buildInputs = [ pkgs.boost189 ];
          meta.mainProgram = "Wallet-Fingerprint-Data-Collection";
        };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.scan;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.stdenv.hostPlatform.system}.scan ];
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
