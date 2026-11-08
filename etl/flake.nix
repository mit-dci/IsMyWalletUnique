{
  description = "Turn data-collection scans into the JSON-formatted export";

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
        }).config.build;
    in
    {
      packages = forAllSystems (pkgs: {
        fingerprints = pkgs.writeShellApplication {
          name = "fingerprints";
          runtimeInputs = [ pkgs.duckdb ];
          text = ''
            if [ $# -ne 2 ]; then
              echo "usage: fingerprints SCAN.duckdb OUT.json" >&2
              exit 2
            fi
            scan=$1
            out=$2
            tmp=$(mktemp "$out.XXXXXX")
            trap 'rm -f "$tmp"' EXIT
            duckdb -bail -readonly -noheader -list "$scan" < ${./fingerprints.sql} > "$tmp"
            mv "$tmp" "$out"
            trap - EXIT
            echo "wrote $out" >&2
          '';
        };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.fingerprints;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.duckdb ]; };
      });

      formatter = forAllSystems (pkgs: (treefmtFor pkgs).wrapper);

      checks = forAllSystems (pkgs: {
        formatting = (treefmtFor pkgs).check self;
      });
    };
}
