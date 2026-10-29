#!/usr/bin/env bash
# Convenience runner: ./run.sh [starter|full|repro]
set -euo pipefail
cd "$(dirname "$0")"
PY="${PYTHON:-python3}"
case "${1:-starter}" in
  starter) exec "$PY" -m src.pipeline --scale starter --outdir output/starter ;;
  full)    exec "$PY" -m src.pipeline --scale full --outdir output/full ;;
  repro)
    "$PY" -m src.pipeline --scale full --outdir output/full
    "$PY" -m src.pipeline --scale full --outdir output/full_rerun
    exec "$PY" -m src.pipeline --verify output/full output/full_rerun
    ;;
  *) echo "usage: ./run.sh [starter|full|repro]" >&2; exit 1 ;;
esac
