#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION_ENV="$ROOT/state/session.env"
if [ -f "$SESSION_ENV" ]; then
  # shellcheck disable=SC1090
  source "$SESSION_ENV"
fi

export PATH="$HOME/.npm-global/bin:$PATH"
CDP_PORT="${CDP_PORT:-9222}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$HOME/下载}"
if [ ! -d "$DOWNLOAD_DIR" ]; then
  DOWNLOAD_DIR="${DOWNLOAD_DIR_FALLBACK:-$HOME/Downloads}"
fi

TOPIC="${1:-测试主题}"
PROMPT="${2:-为\"$TOPIC\"生成一张适合小红书封面的高质量插画图片，构图清晰，主体突出，色彩干净，适合移动端浏览。}"
RUN_DATE="$(date +%F)"
RUN_TS="$(date +%F-%H%M%S)"
SAFE_TOPIC="$(printf '%s' "$TOPIC" | tr ' /' '__')"
OUT_DIR="$ROOT/artifacts/$RUN_DATE/$RUN_TS-$SAFE_TOPIC"
mkdir -p "$OUT_DIR/screenshots"

run_ab() {
  agent-browser --cdp "$CDP_PORT" "$@"
}

json_escape() {
  python3 - <<'PY' "$1"
import json,sys
print(json.dumps(sys.argv[1], ensure_ascii=False))
PY
}

STARTED_AT="$(date --iso-8601=seconds)"
PROMPT_JSON=$(json_escape "$PROMPT")
TOPIC_JSON=$(json_escape "$TOPIC")
cat > "$OUT_DIR/run.json" <<JSON
{
  "topic": $TOPIC_JSON,
  "prompt": $PROMPT_JSON,
  "startedAt": "$STARTED_AT",
  "status": "started"
}
JSON
printf '%s\n' "$PROMPT" > "$OUT_DIR/prompt.txt"

before_list="$OUT_DIR/downloads.before.txt"
after_list="$OUT_DIR/downloads.after.txt"
ls -1t "$DOWNLOAD_DIR" 2>/dev/null > "$before_list" || true

run_ab open "https://gemini.google.com/"
run_ab wait 3000 || true
run_ab screenshot "$OUT_DIR/screenshots/01-open.png" || true
run_ab snapshot -i --json > "$OUT_DIR/01-open.snapshot.json" || true

# Optional reference uploads (verified live with hidden Filedata input workaround)
REFS_DIR="${REFS_DIR:-}"
if [ -n "$REFS_DIR" ] && [ -d "$REFS_DIR" ]; then
  mapfile -t REF_FILES < <(find "$REFS_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -n 3)
  if [ "${#REF_FILES[@]}" -gt 0 ]; then
    run_ab click @e44 || true
    run_ab wait 500 || true
    run_ab click @e49 || true
    run_ab wait 300 || true
    run_ab eval '
(() => {
  const input = document.querySelector("input[type=file]");
  if (!input) return {ok:false};
  input.style.display = "block";
  input.style.visibility = "visible";
  input.style.opacity = "1";
  input.style.pointerEvents = "auto";
  return {ok:true};
})()'
    run_ab upload 'input[type=file]' "${REF_FILES[@]}"
    run_ab wait 3000 || true
    printf '%s\n' "${REF_FILES[@]}" > "$OUT_DIR/uploaded-refs.txt"
    run_ab screenshot "$OUT_DIR/screenshots/01b-uploaded-refs.png" || true
  fi
fi

# Verified live UI sequence
run_ab click @e31 2>/dev/null || run_ab click @e49 || true
run_ab fill @e31 "$PROMPT" 2>/dev/null || run_ab fill @e49 "$PROMPT"
run_ab snapshot -i --json > "$OUT_DIR/02-filled.snapshot.json" || true
run_ab click @e36 2>/dev/null || run_ab click @e55
run_ab wait 12000 || true
run_ab screenshot "$OUT_DIR/screenshots/02-generating.png" || true

# Wait until result actions show up. Retry a few times.
found_download=0
for i in 1 2 3 4 5; do
  run_ab snapshot -i -c > "$OUT_DIR/03-result-$i.snapshot.txt" || true
  if grep -q '下载完整尺寸的图片' "$OUT_DIR/03-result-$i.snapshot.txt"; then
    found_download=1
    break
  fi
  run_ab wait 5000 || true
done

if [ "$found_download" -ne 1 ]; then
  run_ab screenshot "$OUT_DIR/screenshots/03-timeout.png" || true
  cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "generation_timeout",
  "message": "Did not detect download button within retry window."
}
JSON
  echo "Generation did not finish in time: $OUT_DIR"
  exit 2
fi

run_ab screenshot "$OUT_DIR/screenshots/03-result.png" || true
run_ab click @e38
sleep 5
ls -1t "$DOWNLOAD_DIR" 2>/dev/null > "$after_list" || true

NEW_FILE="$(python3 - <<'PY' "$before_list" "$after_list"
import sys
before=set()
after=[]
try:
    before=set(open(sys.argv[1], encoding='utf-8', errors='ignore').read().splitlines())
except FileNotFoundError:
    pass
try:
    after=open(sys.argv[2], encoding='utf-8', errors='ignore').read().splitlines()
except FileNotFoundError:
    after=[]
for name in after:
    if name and name not in before:
        print(name)
        break
PY
)"

DOWNLOADED_TO=""
if [ -n "$NEW_FILE" ] && [ -f "$DOWNLOAD_DIR/$NEW_FILE" ]; then
  mkdir -p "$OUT_DIR/downloads"
  cp "$DOWNLOAD_DIR/$NEW_FILE" "$OUT_DIR/downloads/$NEW_FILE"
  DOWNLOADED_TO="$OUT_DIR/downloads/$NEW_FILE"
fi

cat > "$OUT_DIR/result.json" <<JSON
{
  "status": "ok",
  "downloadDetected": $( [ -n "$DOWNLOADED_TO" ] && echo true || echo false ),
  "downloadedTo": $(json_escape "$DOWNLOADED_TO"),
  "finishedAt": "$(date --iso-8601=seconds)"
}
JSON

echo "Run finished: $OUT_DIR"
if [ -n "$DOWNLOADED_TO" ]; then
  echo "Downloaded file copied to: $DOWNLOADED_TO"
else
  echo "No new download file was confidently identified; inspect $DOWNLOAD_DIR and $OUT_DIR/screenshots"
fi
