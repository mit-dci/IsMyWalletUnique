# Wallet Fingerprints

A systematic overview of Bitcoin wallet fingerprints. This is a work in progress while we build the live version.

- `data-collection/` scans a Bitcoin Core node and writes per-transaction fingerprints to a DuckDB file.
- `etl/` aggregates a scan into the `fingerprints.json` the website loads.
- `docs/` is the static website.
