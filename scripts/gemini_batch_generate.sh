#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOPIC="${1:-测试主题}"
CITY="${2:-$TOPIC}"
THEME="${3:-$TOPIC}"
TARGET_COUNT="${4:-5}"
REFS_DIR="${REFS_DIR:-}"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
SAFE_TOPIC="$(printf '%s' "$TOPIC" | tr ' /' '__')"
BATCH_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$SAFE_TOPIC-batch"
mkdir -p "$BATCH_DIR/prompts" "$BATCH_DIR/runs"

python3 "$ROOT/scripts/prompt_sets.py" body --topic "$TOPIC" --city "$CITY" --theme "$THEME" > "$BATCH_DIR/prompts/body-prompts.json"

python3 - <<'PY' "$BATCH_DIR/prompts/body-prompts.json" "$BATCH_DIR/prompts/index.tsv" "$TARGET_COUNT"
import json,sys,math
items=json.load(open(sys.argv[1],encoding='utf-8'))
target=int(sys.argv[3])
# repeat prompt families until target count is reached
rows=[]
idx=1
while len(rows) < target:
    for item in items:
        rows.append((idx, item['name'], item['prompt']))
        idx += 1
        if len(rows) >= target:
            break
with open(sys.argv[2],'w',encoding='utf-8') as f:
    for idx,name,prompt in rows:
        f.write(f"{idx}\t{name}\t{prompt}\n")
PY

SUCCESS_LOG="$BATCH_DIR/results.tsv"
: > "$SUCCESS_LOG"

while IFS=$'\t' read -r idx name prompt; do
  [ -n "$idx" ] || continue
  RUN_LOG="$BATCH_DIR/runs/${idx}-${name}.log"
  echo "Running prompt $idx/$TARGET_COUNT: $name"
  if REFS_DIR="$REFS_DIR" bash "$ROOT/scripts/gemini_generate_run.sh" "$TOPIC" "$prompt" > "$RUN_LOG" 2>&1; then
    echo -e "$idx\t$name\tOK\trefs-attached+sent\t$RUN_LOG" >> "$SUCCESS_LOG"
  else
    status=run_failed
    for s in upload_failed refs_not_attached prompt_box_missing send_not_started generation_timeout; do
      if grep -q "$s" "$RUN_LOG" 2>/dev/null; then status="$s"; break; fi
    done
    echo -e "$idx\t$name\tFAIL\t$status\t$RUN_LOG" >> "$SUCCESS_LOG"
  fi
  sleep 2
done < "$BATCH_DIR/prompts/index.tsv"

echo "$BATCH_DIR"
