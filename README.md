# Explainable Customer Segmentation & Action Recommendation

End-to-end, fully reproducible pipeline that builds explainable customer
segments from purchase, engagement and service data, then recommends actions
under consent and margin constraints, with labeled edge cases, ground truth,
and a two-phase validation suite.

**100% synthetic data. Fixed seed `20261022`. Reference date 2026-10-22.**

## Quickstart

```bash
python -m src.pipeline --scale starter --outdir output/starter   # ~2 s, 1K customers
python -m src.pipeline --scale full    --outdir output/full      # ~2 min, 50K customers
python -m src.pipeline --verify output/full output/full_rerun    # reproducibility proof
```

Requirements: Python 3.9+, numpy, pandas (see `requirements.txt`).
The starter and full datasets come from the SAME generator; only scale
parameters differ.

## What it produces (full scale)

| | |
|---|---|
| 50,000 customers, 200,000 purchase orders, 13,177 return orders | 1,000,000 engagement events |
| 77,814 support cases, 151,049 consent history rows | 113,886 segment memberships (2 snapshots) |
| 50,000 logged action decisions (37,081 sent / 12,919 suppressed with reasons) | 37,081 outcome rows |
| 49 labeled anomalies + 100 audit rows in `ground_truth.csv` | 81/81 baseline validation checks |

Formats per run: `csv/` (all tables), `json/` (reference tables at full scale,
all tables at starter scale), `seed.sqlite` (full relational seed with DDL,
FKs, CHECK constraints and views), `sql/` (INSERT statements),
`reports/` (segment/action/suppression aggregates + published RFM thresholds),
`manifest.json` (per-file SHA-256 + row counts), `validation_summary.md`.

## Headline results

- **Validation**: 81/81 baseline integrity checks pass; any failure aborts.
- **Anomaly detection**: all four required edge cases (conflicting exclusive
  segments, consent violation, return not netted from spend, outcome
  misattribution) are injected AFTER the clean baseline, labeled in ground
  truth, and re-detected with precision = recall = F1 = 1.0.
- **Explainability**: every membership row stores its metrics, R/F/M scores and
  a human-readable reason string; every suppressed recommendation stores the
  blocking rule.
- **Reproducibility**: two independent full-scale runs produce byte-identical
  files (all 29 SHA-256 checksums match, SQLite included).

Details with tables: [`docs/RESULTS.md`](docs/RESULTS.md).

## How it works

```
generate masters (Customer, Product)
  -> transactions (Order + OrderLine + returns; integer cents; lifecycle timestamps)
  -> events (Engagement 1M, SupportCase with derived cost-to-serve, append-only Consent)
  -> metrics recomputed from sources -> RFM (R/M quintiles published, F business cut-points)
  -> segments via first-match-wins ladder (10 lifecycle, mutually exclusive) + 3 overlays
     computed at TWO snapshots (history preserved, never overwritten)
  -> action decision engine (eligibility + ordered suppression: consent / open case / margin)
  -> outcomes from documented per-segment probability tables
  -> [phase A validation must pass] -> labeled anomaly injection + ground truth
  -> [phase B detection scored vs ground truth] -> exports + manifest
```

## Repository layout

```
src/                 generator, segmentation, actions, validators, exports, orchestrator
sql/schema.sql       DDL: 14 tables, CHECK constraints, FKs, indexes, 3 views
docs/
  data_dictionary.md field-level dictionary, IDs, conventions
  business_rules.md  metrics, RFM, segment ladder, action catalog, suppression, probabilities
  schema_erd.md      ERD + cardinality + lifecycle states
  walkthrough.md     from-basics explainer incl. interview Q&A
  HOW_IT_WAS_BUILT.md build log incl. bugs found and fixed
  RESULTS.md         measured results
output/
  starter/           small dataset (1K customers) for fast iteration
  full/              full dataset (50K/200K/1M)
  repro_check.md     two-run checksum comparison
scripts/smoke_test.py  generator-level smoke checks
Makefile            make starter / full / repro / clean
```

## Key design decisions (short list)

1. **Money is integer cents**; order totals reconcile exactly against lines.
2. **Returns are separate orders** with negative amounts and `parent_order_id`,
   so net spend nets returns by construction.
3. **Consent is append-only history**; state at any instant is reconstructable,
   which consent-violation detection depends on.
4. **Segments are computed, never generated**: a hidden archetype drives
   behaviour, published labels come from documented rules on that behaviour.
5. **Ground truth is separate** from all inputs and never leaks into features.
6. **No wall-clock calls**: as_of is a constant, so the seed alone determines
   every byte of output.

## Lawful use / provenance

No external or personal data was used. Names and emails are synthesized from
fixed word lists; the schema borrows generic e-commerce conventions only.
The generated datasets may be shared freely with attribution to this generator.
