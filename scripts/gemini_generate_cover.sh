#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOPIC="${1:-测试主题封面}"
CITY="${2:-$TOPIC}"
THEME="${3:-$TOPIC}"
REFS_DIR="${REFS_DIR:-}"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
SAFE_TOPIC="$(printf '%s' "$TOPIC" | tr ' /' '__')"
COVER_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$SAFE_TOPIC-cover"
mkdir -p "$COVER_DIR"

python3 "$ROOT/scripts/prompt_sets.py" cover --topic "$TOPIC" --city "$CITY" --theme "$THEME" > "$COVER_DIR/cover-prompts.json"
PROMPT=$(python3 - <<'PY' "$COVER_DIR/cover-prompts.json"
import json,sys
items=json.load(open(sys.argv[1],encoding='utf-8'))
print(items[0]['prompt'])
PY
)

REFS_DIR="$REFS_DIR" bash "$ROOT/scripts/gemini_generate_run.sh" "$TOPIC-封面" "$PROMPT"

echo "$COVER_DIR"
