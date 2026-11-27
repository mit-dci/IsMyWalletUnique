#!/usr/bin/env bash
# Scan heights START_HEIGHT..END_HEIGHT into one DuckDB file per CHUNK_SIZE
# blocks, named scan-<chain>-<start>-<end>.duckdb with both heights inclusive
# and zero-padded.
#
# START_HEIGHT must be a multiple of CHUNK_SIZE so chunks from separate runs
# line up. Rerunning over a range already scanned is safe: finished files are
# skipped and an interrupted chunk is resumed. A chunk is written as
# <name>.partial and renamed only once its scan completes, so a file without
# the suffix is always whole.
#
# Every start or resume appends a row to <out_dir>/scan-timings.tsv, so a chunk
# that was interrupted has several rows and its scan time is their sum.
set -euo pipefail

if [[ $# -lt 4 || $# -gt 6 ]]; then
    echo "usage: $0 <data_dir> <out_dir> <start_height> <end_height> [chunk_size=50000] [chain=mainnet]" >&2
    exit 2
fi
data_dir=$1
out_dir=$2
start_height=$3
end_height=$4
chunk_size=${5:-50000}
chain=${6:-mainnet}

if ((start_height % chunk_size != 0)); then
    echo "start_height $start_height is not a multiple of chunk_size $chunk_size" >&2
    exit 2
fi
if ((start_height > end_height)); then
    echo "start_height $start_height is above end_height $end_height" >&2
    exit 2
fi

bin="$(dirname "$0")/target/release/Wallet-Fingerprint-Data-Collection"
mkdir -p "$out_dir"
timings="$out_dir/scan-timings.tsv"
if [[ ! -e $timings ]]; then
    printf 'file\tstart_height\tend_height\taction\tstarted_at\tfinished_at\tseconds\texit_code\n' >"$timings"
fi

for ((start = start_height; start <= end_height; start += chunk_size)); do
    stop=$((start + chunk_size - 1))
    ((stop > end_height)) && stop=$end_height
    final=$(printf '%s/scan-%s-%07d-%07d.duckdb' "$out_dir" "$chain" "$start" "$stop")
    partial="$final.partial"

    if [[ -e $final ]]; then
        echo "== skip $(basename "$final"): already complete"
        continue
    fi
    started_at=$(date -u +%FT%TZ)
    started_s=$(date +%s)
    echo "== $started_at $(basename "$final")"
    status=0
    if [[ -e $partial ]]; then
        action=resume
        "$bin" resume "$data_dir" "$partial" || status=$?
    else
        action=start
        "$bin" start "$data_dir" "$partial" --chain "$chain" \
            --start-height "$start" --end-height "$stop" || status=$?
    fi
    printf '%s\t%d\t%d\t%s\t%s\t%s\t%d\t%d\n' "$(basename "$final")" "$start" "$stop" \
        "$action" "$started_at" "$(date -u +%FT%TZ)" $(($(date +%s) - started_s)) "$status" >>"$timings"
    ((status == 0)) || exit "$status"
    mv "$partial" "$final"
done
echo "== $(date -u +%FT%TZ) done"
