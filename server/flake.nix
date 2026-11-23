{
  description = "Caddy server for the latest wallet fingerprints.json";

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
          settings.formatter.caddy = {
            command = "${pkgs.bash}/bin/bash";
            options = [
              "-euc"
              ''
                for file in "$@"; do
                  ${pkgs.lib.getExe pkgs.caddy} fmt --overwrite "$file"
                done
              ''
              "--"
            ];
            includes = [
              "Caddyfile"
              "Caddyfile.*"
              "*.Caddyfile"
            ];
          };
        }).config.build;
    in
    {
      packages = forAllSystems (pkgs: {
        # Keep the plugin version in sync with the Dockerfile.
        caddy = pkgs.caddy.withPlugins {
          plugins = [ "github.com/mholt/caddy-ratelimit@v0.1.1-0.20260612195517-5625512f24f6" ];
          hash = "sha256-lJOVCCLLVOnewSELRr6gzrRryFYeXbpCyOiGumSZ1dc=";
        };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.caddy;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.caddy ];
        };
      });

      formatter = forAllSystems (pkgs: (treefmtFor pkgs).wrapper);

      checks = forAllSystems (pkgs: {
        formatting = (treefmtFor pkgs).check self;
        caddyfile =
          pkgs.runCommand "caddyfile-validate"
            {
              nativeBuildInputs = [ self.packages.${pkgs.stdenv.hostPlatform.system}.caddy ];
            }
            ''
              export HOME=$TMPDIR XDG_DATA_HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR
              DOMAIN=localhost caddy validate --adapter caddyfile --config ${./Caddyfile}
              touch $out
            '';
      });
    };
}
