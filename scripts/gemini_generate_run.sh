#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="${AGENT_BROWSER_SESSION:-gemini-xhs}"
STATE_FILE="${STATE_FILE:-$ROOT/state/gemini-auth.json}"
TOPIC="${1:-测试主题}"
PROMPT="${2:-为\"$TOPIC\"生成一张适合小红书封面的高质量图片，构图清晰，主体突出，色彩干净，适合移动端浏览。}"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
SAFE_TOPIC="$(printf '%s' "$TOPIC" | tr ' /' '__')"
OUT_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$SAFE_TOPIC"
mkdir -p "$OUT_DIR/screenshots"

cat > "$OUT_DIR/run.json" <<JSON
{
  "topic": "$TOPIC",
  "prompt": "$PROMPT",
  "startedAt": "$(date --iso-8601=seconds)",
  "status": "started"
}
JSON

printf '%s\n' "$PROMPT" > "$OUT_DIR/prompt.txt"

if [ ! -f "$STATE_FILE" ]; then
  echo "Missing state file: $STATE_FILE"
  echo "Run scripts/gemini_generate_session.sh first."
  exit 1
fi

agent-browser --session "$SESSION" state load "$STATE_FILE"
agent-browser --session "$SESSION" open "https://gemini.google.com/"
agent-browser --session "$SESSION" wait 3000 || true
agent-browser --session "$SESSION" screenshot "$OUT_DIR/screenshots/01-open.png" || true
agent-browser --session "$SESSION" snapshot -i --json > "$OUT_DIR/generation.snapshot.json" || true

cat > "$OUT_DIR/NEXT_STEPS.md" <<'EOF'
This run created the artifact folder and loaded the Gemini session.

Complete the Gemini-specific interaction logic next:
1. inspect generation.snapshot.json
2. identify the prompt box/button refs
3. fill prompt
4. trigger generation
5. wait for result images
6. download or capture result URLs
EOF

echo "Initialized Gemini web run at: $OUT_DIR"
