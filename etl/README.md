# etl

Aggregates a data-collection scan (a DuckDB file) into the `fingerprints.json` the website in `docs/` loads.
Run `nix run .#fingerprints -- SCAN.duckdb ../docs/fingerprints.json` from this directory.
