-- Aggregates a data-collection scan into for the website's fingerprints.json.
--
-- Run against the scan file opened read-only, in list mode without a header:
--   duckdb -bail -readonly -noheader -list scan.duckdb < fingerprints.sql
-- It prints one JSON document.
--
-- Values are the collector's own names (data-collection/features.md): a facet
-- is the suffixes of its true `<prefix>__<suffix>` columns joined with `+`, in
-- column order, or `none` when no column is set. Columns without a prefix,
-- like `reveals_inscription`, contribute their whole name.
--
-- `state` joins the facets with `|` in this order: version, seq, lock,
-- sighash, family, lowr, data, input_order, output_order. Sighash suffixes can contain `|`, so readers
-- split `state` from both ends.

WITH
done AS (
    SELECT min(height) AS lo, max(height) AS hi, count(*) AS blocks FROM blocks
),

named AS (
    SELECT
        fp_version,
        fp_any_low_r_grinding,
        fp_outputs_bip69_sorted,
        CASE WHEN COLUMNS('^((fp_sequence_shape|h_locktime_shape|h_sighash|input_type|output_type|fp_input_order)__.*|reveals_inscription|fp_any_taproot_annex)$')
            THEN regexp_replace(alias(COLUMNS('^((fp_sequence_shape|h_locktime_shape|h_sighash|input_type|output_type|fp_input_order)__.*|reveals_inscription|fp_any_taproot_annex)$')), '^.*__', '')
        END
    FROM txs
),

facets AS (
    SELECT
        fp_version::VARCHAR AS version,
        coalesce(nullif(concat_ws('+', *COLUMNS('^fp_sequence_shape__')), ''), 'none') AS seq,
        coalesce(nullif(concat_ws('+', *COLUMNS('^h_locktime_shape__')), ''), 'none') AS lock,
        coalesce(nullif(concat_ws('+', *COLUMNS('^h_sighash__')), ''), 'none') AS sighash,
        coalesce(nullif(concat_ws('+', *COLUMNS('^input_type__')), ''), 'none') AS family,
        fp_any_low_r_grinding::VARCHAR AS lowr,
        coalesce(nullif(concat_ws('+',
            *COLUMNS('^output_type__(op_return.*|p2ms|unknown)$'), reveals_inscription, fp_any_taproot_annex
        ), ''), 'none') AS data,
        coalesce(nullif(concat_ws('+', *COLUMNS('^fp_input_order__')), ''), 'none') AS input_order,
        fp_outputs_bip69_sorted::VARCHAR AS output_order
    FROM named
),

counted AS (
    SELECT
        *,
        concat_ws('|', version, seq, lock, sighash, family, lowr, data, input_order, output_order) AS state,
        count(*) AS n
    FROM facets
    GROUP BY ALL
),

ranked AS (
    SELECT *, row_number() OVER (ORDER BY n DESC, state) - 1 AS id FROM counted
)

SELECT json_object(
    'window', json_object('start_height', lo, 'end_height', hi, 'blocks', blocks),
    'total', (SELECT sum(n) FROM ranked),
    'unit', 'transactions',
    'note', 'Each record is one fingerprint. Counts are transactions in the window. '
         || 'Values are the collector''s column names; sets are joined with +.',
    'fingerprints', (
        SELECT to_json(list(json_object(
            'version', version, 'seq', seq, 'lock', lock, 'sighash', sighash, 'family', family,
            'lowr', lowr, 'data', data, 'input_order', input_order, 'output_order', output_order,
            'id', id, 'n', n, 'state', state
        ) ORDER BY id))
        FROM ranked
    )
)
FROM done, scan
WHERE CASE
    WHEN lo IS DISTINCT FROM start_height OR hi IS DISTINCT FROM end_height OR blocks <> end_height - start_height + 1
    THEN error(format('scan is incomplete: blocks {}..{} of {}..{} are done', lo, hi, start_height, end_height))
    ELSE true
END;
