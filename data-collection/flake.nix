{
  description = "Scan a Bitcoin Core data directory into a DuckDB file of wallet fingerprints";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
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
          buildInputs = [ pkgs.boost ];
          meta.mainProgram = "Wallet-Fingerprint-Data-Collection";
        };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.scan;
      });
    };
}
