#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOPIC="${1:-测试主题}"
CITY="${2:-$TOPIC}"
THEME="${3:-$TOPIC}"
REFS_DIR="${REFS_DIR:-}"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
SAFE_TOPIC="$(printf '%s' "$TOPIC" | tr ' /' '__')"
BATCH_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$SAFE_TOPIC-batch"
mkdir -p "$BATCH_DIR/prompts" "$BATCH_DIR/runs"

python3 "$ROOT/scripts/prompt_sets.py" body --topic "$TOPIC" --city "$CITY" --theme "$THEME" > "$BATCH_DIR/prompts/body-prompts.json"

python3 - <<'PY' "$BATCH_DIR/prompts/body-prompts.json" "$BATCH_DIR/prompts/index.tsv"
import json,sys
items=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],'w',encoding='utf-8') as f:
    for i,item in enumerate(items,1):
        f.write(f"{i}\t{item['name']}\t{item['prompt']}\n")
PY

while IFS=$'\t' read -r idx name prompt; do
  [ -n "$idx" ] || continue
  RUN_LOG="$BATCH_DIR/runs/${idx}-${name}.log"
  OUT_DIR="$BATCH_DIR/runs/${idx}-${name}"
  mkdir -p "$OUT_DIR"
  echo "Running prompt $idx/$name"
  REFS_DIR="$REFS_DIR" bash "$ROOT/scripts/gemini_generate_run.sh" "$TOPIC" "$prompt" > "$RUN_LOG" 2>&1 || true
  printf '%s\n' "$prompt" > "$OUT_DIR/prompt.txt"
done < "$BATCH_DIR/prompts/index.tsv"

echo "$BATCH_DIR"
