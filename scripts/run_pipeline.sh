#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
TOPIC="${1:-manual-topic}"
OUT_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$TOPIC"

mkdir -p "$OUT_DIR/screenshots"

cat > "$OUT_DIR/run.json" <<JSON
{
  "topic": "$TOPIC",
  "startedAt": "$(date --iso-8601=seconds)",
  "status": "initialized",
  "notes": "Replace this shell scaffold with real browser automation steps."
}
JSON

echo "Initialized run directory: $OUT_DIR"
echo "Next: call agent-browser tasks / browser automation here"
