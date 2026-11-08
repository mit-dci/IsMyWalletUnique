/* Facet values arrive as the collector's names (data-collection/features.md),
   with sets joined by "+". Display names are applied only when rendering. */

const FACETS = [
  ["version", "Version"],
  ["seq", "Sequence"],
  ["lock", "Locktime"],
  ["input_order", "Input order"],
  ["output_order", "Output order"],
  ["family", "Script"],
  ["sighash", "Sighash"],
  ["lowr", "Low-R grinding"],
  ["data", "Data Carrying Mechanism"],
];

const LABEL = {
  version: { 1: "v1", 2: "v2", 3: "v3" },
  seq: {
    final: "final", rbf: "RBF", locktime_no_rbf: "locktime, no RBF",
    relative_blocks: "relative blocks", relative_time: "relative time", other: "other",
  },
  lock: {
    none: "none", height_exact: "current height", height_delta_1: "1 block back",
    height_delta_2_9: "2–9 blocks back", height_delta_10_99: "10–99 blocks back",
    height_delta_100_plus: "100+ blocks back", height_future: "future height", timestamp: "timestamp",
  },
  input_order: {
    single: "single", ascending: "ascending", descending: "descending", bip69: "BIP69",
    historical: "historical", unknown: "unknown",
  },
  output_order: { true: "BIP69", false: "not BIP69" },
  family: {
    p2pk: "P2PK", p2pk_lax_der: "P2PK lax DER", p2pkh: "P2PKH", p2pkh_lax_der: "P2PKH lax DER",
    p2sh_p2wpkh: "P2SH-P2WPKH", p2wpkh: "P2WPKH", p2ms: "bare multisig", p2ms_lax_der: "bare multisig lax DER",
    p2sh: "P2SH", p2sh_p2wsh: "P2SH-P2WSH", p2wsh: "P2WSH",
    p2tr_keypath: "taproot key path", p2tr_scriptpath: "taproot script path", p2a: "anchor", unknown: "unknown",
  },
  sighash: {
    none: "no signature", DEFAULT: "default", ALL: "ALL", NONE: "NONE", SINGLE: "SINGLE",
    "ALL|ANYONECANPAY": "ALL|ACP", "NONE|ANYONECANPAY": "NONE|ACP", "SINGLE|ANYONECANPAY": "SINGLE|ACP",
    UNKNOWN: "unknown",
  },
  lowr: { true: "yes", false: "no" },
  data: {
    none: "none", op_return: "OP_RETURN", op_return_runestone: "runestone", reveals_inscription: "inscription",
    op_return_witness_commitment: "witness commitment", op_return_omni: "Omni",
    op_return_stacks_block_commit: "Stacks commit", op_return_bip47: "BIP47",
    op_return_len_1: "OP_RETURN len 1", op_return_len_20: "OP_RETURN len 20", op_return_len_80: "OP_RETURN len 80",
    op_return_rsk: "RSK", op_return_coredao: "CoreDAO", op_return_exsat: "exSat", op_return_hathor: "Hathor",
    p2ms: "bare multisig", unknown: "unknown script", fp_any_taproot_annex: "taproot annex",
  },
};

const TIP = {
  version: { 1: "nVersion 1.", 2: "nVersion 2.", 3: "nVersion 3. TRUC." },
  seq: {
    final: "nSequence 0xffffffff.",
    rbf: "nSequence 0xfffffffd. Signals RBF.",
    locktime_no_rbf: "nSequence 0xfffffffe. Locktime is enabled and RBF is not signaled.",
    relative_blocks: "BIP68 relative lock, counted in blocks.",
    relative_time: "BIP68 relative lock, counted in 512-second units.",
    other: "nSequence has the disable bit set and is not final, RBF, or locktime-only.",
  },
  lock: {
    none: "nLockTime is 0.",
    height_exact: "nLockTime equals the confirming height.",
    height_delta_1: "nLockTime is 1 block below the confirming height.",
    height_delta_2_9: "nLockTime is 2–9 blocks below the confirming height.",
    height_delta_10_99: "nLockTime is 10–99 blocks below the confirming height.",
    height_delta_100_plus: "nLockTime is 100 or more blocks below the confirming height.",
    height_future: "nLockTime is above the confirming height.",
    timestamp: "nLockTime is a timestamp.",
  },
  sighash: {
    none: "No input signatures.",
    DEFAULT: "64-byte Schnorr signature with no sighash byte.",
    UNKNOWN: "Sighash flag outside the standard values.",
  },
};

const parts = (value) => String(value).split("+");

function facetLabel(key, value) {
  if (value == null || value === "") return "";
  return parts(value).map((part) => (LABEL[key] && LABEL[key][part]) || part).join(" + ");
}

function tipFor(key, value) {
  if (value == null || value === "") return "";
  return parts(value).map((part) => (TIP[key] && TIP[key][part]) || facetLabel(key, part)).join(" ");
}

function fingerprintWords(fp) {
  if (!fp) return [];
  return FACETS.map(([key]) => facetLabel(key, fp[key])).filter(Boolean);
}

function oneInCount(p) {
  if (!(p > 0)) return null;
  if (p >= 1) return 1;
  return Math.max(2, Math.round(1 / p));
}

function windowLine(data) {
  const span = data.window.end_height - data.window.start_height + 1;
  return `Collected over ${span.toLocaleString()} blocks`;
}

function collapsePrints(rows) {
  const by = new Map();
  for (const fp of rows) {
    const state = FACETS.map(([key]) => fp[key]).join("|");
    const prev = by.get(state);
    if (!prev) {
      by.set(state, { ...fp, state });
    } else prev.n += fp.n;
  }
  return [...by.values()].sort((a, b) => b.n - a.n).map((fp, id) => ({ ...fp, id }));
}
