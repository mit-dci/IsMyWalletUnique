# etl

Aggregates a data-collection scan (a DuckDB file) into the `fingerprints.json` the website in `client/` loads.
The server in `server/` serves it from `server/public/`.
Run `nix run .#fingerprints -- SCAN.duckdb ../server/public/fingerprints.json` from this directory.
